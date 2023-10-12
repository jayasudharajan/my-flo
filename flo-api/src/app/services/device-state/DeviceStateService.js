import AWS from 'aws-sdk';
import _ from 'lodash';
import moment from 'moment';
import redis from 'redis';
import t from 'tcomb-validation';

import ClientService from '../../services/client/ClientService';
import DIFactory from '../../../util/DIFactory';
import DeviceStateLogTable from './DeviceStateLogTable';
import ICDService from '../icd-v1_5/ICDService';
import InfoService from '../info/InfoService';
import Logger from '../utils/Logger';
import NotFoundException from '../utils/exceptions/NotFoundException';
import S3Utils from '../utils/S3Utils';
import config from '../../../config/config';
import googleSmartHomeStateMapping from './google-smart-home/stateMapping';
import TState from './models/TState';
import deviceStates, { SystemModeState, ValveState, LeakState, OnlineState } from './models/DevicesStates';

const DEVICE_STATE_PREFIX = 'device-state.';

class DeviceStateService {

  constructor(deviceStateLogTable, icdService, infoService, clientService, redisClient, s3, smartHome, randomUuid, logger) {
    this.deviceStateLogTable = deviceStateLogTable;
    this.icdService = icdService;
    this.infoService = infoService;
    this.clientService = clientService;
    this.redisClient = redisClient;
    this.s3Utils = new S3Utils(s3);
    this.smartHome = smartHome;
    this.randomUuid = randomUuid;
    this.logger = logger;

    this.smartHomeClient = undefined;
    this.clientIdSet = new Set();
    this.clientHandlers = {};
    config.clientIds && config.clientIds.split(',').forEach(nameAndIdPair => {
      const [clientName, clientId] = nameAndIdPair.split(':');
      this.clientIdSet.add(clientId);
      // TODO: Check this convention / Refactor when we integrate more clients.
      // We may probably want to have each integration in its own file.
      this.clientHandlers[clientId] = {
        handler: '_forwardTo' + clientName,
        pairingSync: '_pairingSync' + clientName,
        stateHandlers: {
          [SystemModeState]: '_mapSystemModeTo' + clientName,
          [ValveState]: '_mapValveStateTo' + clientName,
          [LeakState]: '_mapLeakStateTo' + clientName,
          [OnlineState]: '_mapOnlineStateTo' + clientName
        }
      }
    });
  }

  setInitialState(clientName, telemetry) {
    return this['_setInitialStateFor' + clientName](telemetry);
  }

  deleteDeviceState(userId, clientId) {
    return this._isUserIntegratedWithOtherClient(userId, clientId)
      .then(hasOtherIntegrations => {
        if (hasOtherIntegrations) {
          return Promise.resolve([]);
        }

        return this.infoService.users.retrieveByUserId(userId)
          .then(({ items: [user] }) => (user ? user.devices : []));
      })
      .then(devices => {
        if (_.isEmpty(devices)) {
          return false;
        }

        return Promise.all(
          devices.map(device => this._del(this._buildDeviceKey(device.device_id)))
        ).then(() => true);
      })
  }

  pairingSync(data) {
    return this
      ._withUserIdByLocationId(data.location_id)
      .then(userId => {
        return Promise.all([userId, this.clientService.retrieveClientsByUserId(userId)]);
      })
      .then(([userId, { data }]) => {
        return Promise.all(data.map(clientUser => {
          const clientEntry = this.clientHandlers[clientUser.client_id];
          return Promise.resolve()
            .then(() =>
              clientEntry &&
              this[clientEntry.pairingSync] &&
              this[clientEntry.pairingSync](userId)
            )
        }));
      });
  }

  forward(deviceState) {
    if (!this._isStateValid(deviceState)) {
      const msg = 'Legacy or invalid device state.';
      this.logger.warn(deviceState, msg);

      return Promise.resolve({
        forwarded: false,
        reason: msg
      });
    }

    return this
      ._withUserId(deviceState.did)
      .then(userId => {
        this.logger.info(deviceState, 'Forwarding device state');
        return Promise.all([
          this.deviceStateLogTable.createLatest({
            id: deviceState.id,
            state_name: deviceState.sn,
            device_id: deviceState.did,
            current_state: deviceState.st,
            previous_state: deviceState.pst,
            timestamp: deviceState.ts,
            reason: deviceState.rsn,
            created_at: moment.utc().toISOString()
          }),
          this._forwardState(userId, deviceState)
        ]).then(() => {
          this.logger.info('Successfully forwarded device state with id %s', deviceState.id);
          return { forwarded: true };
        });
      });
  }

  _isUserIntegratedWithOtherClient(userId, clientId) {
    return this.clientService.retrieveClientsByUserId(userId)
      .then(({ data }) =>
        !!data.find((e) => e.client_id !== clientId && this.clientIdSet.has(e.client_id))
      );
  }

  _isStateValid(deviceState) {
    return t.validate(deviceState, TState).errors.length === 0;
  }

  _forwardState(userId, deviceState) {
    return this.clientService.retrieveClientsByUserId(userId)
      .then(({ data }) => {
        return Promise.all(data.map(clientUser => {
          const clientEntry = this.clientHandlers[clientUser.client_id];
          if (clientEntry && this[clientEntry.stateHandlers[deviceState.sn]]) {
            return Promise.all([
              this._hset(this._buildDeviceKey(deviceState.did), deviceState.sn, deviceState.st),
              this[clientEntry.handler](clientEntry, userId, deviceState)
            ]);
          } else {
            return Promise.resolve();
          }
        }));
      });
  }

  _setInitialStateForGoogleSmartHome(telemetry) {
    const leakState = _.find(telemetry.currentSensorStateData, (sensorState) => {
      return sensorState.name === 'WaterLeak';
    });
    return this._hmset(this._buildDeviceKey(telemetry.did), [
      SystemModeState, telemetry.sm,
      ValveState, telemetry.v,
      LeakState, leakState && _.invert(googleSmartHomeStateMapping.leakStates)[leakState.currentSensorState],
      OnlineState, _.invert(googleSmartHomeStateMapping.onlineState)[telemetry.online]
    ]);
  }

  _pairingSyncGoogleSmartHome(userId) {
    return this._getGoogleSmartHomeClient()
      .then(smartHomeClient => 
        smartHomeClient.requestSync(userId)
      )
      .catch(err => {
        if (typeof err === 'string') {
          try {
            const errData = JSON.parse(err);

            if (errData.error && (errData.error.code === 404 || errData.error.code === 403)) {
              this.logger.warn(`Actions On Google - User not found or forbidden: ${err}`);
            } else {
              this.logger.error(`Actions On Google error: ${JSON.stringify(errData)}`);
              return Promise.reject(new Error('Actions On Google error.'));
            }
            return Promise.resolve();
          } catch (_err) {
            // NOOP
          }
        } 

        this.logger.error({ err });

        return Promise.reject(err);
      });
  }

  _forwardToGoogleSmartHome(clientEntry, userId, stateInfo) {
    return Promise.all([
      this._getGoogleSmartHomeClient(),
      this._hgetall(this._buildDeviceKey(stateInfo.did))
    ]).then(([smartHomeClient, fullDeviceState]) => {
        const fullUpdatedState = _.transform(deviceStates, (updatedState, deviceStateName) => {
          const state = deviceStateName === stateInfo.sn ? stateInfo.st : fullDeviceState[deviceStateName];
          _.assign(updatedState, this[clientEntry.stateHandlers[deviceStateName]](state));
        }, {});
        const reportStatePayload = {
          requestId: this.randomUuid(),
          agentUserId: userId,
          payload: {
            devices: {
              states: {
                [stateInfo.did]: fullUpdatedState
              }
            }
          }
        };
        this.logger.info(reportStatePayload, 'Reporting state to Google Smart Home');
        return smartHomeClient.reportState(reportStatePayload)
          .catch(err => Promise.reject(
            err.code === 404 ? new NotFoundException("GoogleSmartHome - State or Device not found.") : err)
          );
      });
  }

  _mapSystemModeToGoogleSmartHome(stateValue) {
    return {
      currentModeSettings: {
        mode: googleSmartHomeStateMapping.systemModes[stateValue]
      }
    };
  }

  _mapValveStateToGoogleSmartHome(stateValue) {
    return {
      openPercent: googleSmartHomeStateMapping.valveStates[stateValue]
    };
  }

  _mapLeakStateToGoogleSmartHome(stateValue) {
    return {
      currentSensorStateData: [
        {
          name: 'WaterLeak',
          currentSensorState: googleSmartHomeStateMapping.leakStates[stateValue]
        }
      ]
    };
  }

  _mapOnlineStateToGoogleSmartHome(stateValue) {
    return {
      online: googleSmartHomeStateMapping.onlineState[stateValue]
    };
  }

  _getGoogleSmartHomeClient() {
    return Promise.resolve(this.smartHomeClient || this.s3Utils.retrieveFile(
      config.googleHomeTokenProviderBucket,
      config.googleHomeTokenProviderKey
    ).then(tokenProviderBuffer => {
      const tokenProvider = JSON.parse(tokenProviderBuffer.toString());
      this.smartHomeClient = this.smartHome({ jwt: tokenProvider });
      return this.smartHomeClient;
    }));
  }

  _hset(key, deviceStateName, deviceState) {
    return this._withPromise(done =>
      this.redisClient.hset(key, deviceStateName, deviceState, done)
    );
  }

  _hmset(key, deviceNamesAndStates) {
    return this._withPromise(done =>
      this.redisClient.hmset(key, deviceNamesAndStates, done)
    );
  }

  _hgetall(key) {
    return this._withPromise(done =>
      this.redisClient.hgetall(key, done)
    );
  }

  _del(key) {
    return this._withPromise(done =>
      this.redisClient.del(key, done)
    );
  }

  _withUserIdByLocationId(locationId) {
    return this.infoService.users.retrieveAll({
      filter: {
        '[geo_locations.location_id]': locationId
      }
    })
    .then(({ items: [user] }) =>
      !user || !user.id ?
        Promise.reject(new NotFoundException('User not found')) :
        user.id
    );
  }

  _withUserId(deviceId) {
    return this
      ._withIcdId(deviceId)
      .then(icdId => this.infoService.icds.retrieveByICDId(icdId))
      .then(({ items: [icd] }) =>
        !icd ? Promise.reject(new NotFoundException('Device not found.')) : icd.owner_user_id
      );
  }

  _withIcdId(deviceId) {
    return this
      .icdService
      .retrieveByDeviceId(deviceId)
      .then(({Items: icds}) => {
        if (!icds || icds.length < 1) {
          return Promise.reject(new NotFoundException('Device not found.'))
        }
        return icds[0].id;
      });
  }

  _buildDeviceKey(deviceId) {
    return DEVICE_STATE_PREFIX + deviceId;
  }

  _withPromise(query) {
    return new Promise((resolve, reject) =>
      query((err, result) => err ? reject(err) : resolve(result))
    );
  }
}

export default new DIFactory(
  DeviceStateService,
  [DeviceStateLogTable, ICDService, InfoService, ClientService, redis.RedisClient, AWS.S3, 'SmartHome', 'RandomUuid', Logger]
);
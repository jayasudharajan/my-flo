import uuid from 'uuid';
import tcustom from '../../models/definitions/CustomTypes';
import TPairingData from './models/TPairingData';
import TQRCode from './models/TQRCode';
import TQRCodeV2 from './models/TQRCodeV2';
import InvalidQRCodeException from './models/exceptions/InvalidQRCodeException';
import DeviceAlreadyPairedException from './models/exceptions/DeviceAlreadyPairedException';
import UserAlreadyPairedException from './models/exceptions/UserAlreadyPairedException';
import NotFoundException from '../utils/exceptions/NotFoundException';
import AuthorizationService from '../authorization/AuthorizationService';
import ICDService from '../icd-v1_5/ICDService';
import StockICDService from '../stock-icd/StockICDService';
import MQTTCertService from '../mqtt-cert/MQTTCertService';
import DeviceSystemModeService from '../device-system-mode/DeviceSystemModeService';
import TPairingPermission from './models/TPairingPermission';
import PairingPermissionTable from './PairingPermissionTable';
import { validateMethod } from '../../models/ValidationMixin';
import DIFactory from  '../../../util/DIFactory';
import _ from 'lodash';
import t from 'tcomb-validation';
import ConflictException from '../utils/exceptions/ConflictException';
import Logger from '../utils/Logger';

class PairingService {
  constructor(stockICDService, mqttCertService, pairingPermissionTable, icdService, authorizationService, deviceSystemModeService, logger) {
    this.stockICDService = stockICDService;
    this.mqttCertService = mqttCertService;
    this.pairingPermissionTable = pairingPermissionTable;
    this.icdService = icdService;
    this.authorizationService = authorizationService;
    this.deviceSystemModeService = deviceSystemModeService;
    this.logger = logger;
  }

  parseQRCodeV1(data) {
    const validation = t.validate(data, TQRCode);

    return validation.errors.length ? null : data;
  }

  parseQRCodeV2(data) {
    const obj = data.split('$')
      .filter(substr => substr)
      .map(substr => {
        const [prop, val] = substr.split(':');

        return { [prop.toLowerCase()]: val }
      })
      .reduce((acc, keyValue) => Object.assign(acc, keyValue), {});
    const validation = t.validate(obj, TQRCodeV2);

    return validation.errors.length ? null : obj;
  }

  parseQRData(qrData) {
    const data = qrData.data || qrData;

    if (!_.isString(data)) {
      return this.parseQRCodeV1(data);
    }

    return this.parseQRCodeV2(data);
  }

  ensureUserUniquePairing(userId) {
    return this.retrievePairingsByUserId(userId)
      .then(pairedDevices => {

        if (pairedDevices.length) {
          return Promise.reject(new UserAlreadyPairedException());
        }
      });
  }

  initPairing(userId, qrData) {
    const parsedQRData = this.parseQRData(qrData);

    if (!parsedQRData) {
      return Promise.reject(new InvalidQRCodeException());
    }

    const { i: id, e: icd_uuid } = parsedQRData;

    return this.stockICDService.retrieve(id)
      .then(stockICD => {

        if (!stockICD || stockICD.icd_uuid != icd_uuid) {
          return Promise.reject(new InvalidQRCodeException());
        }

        return Promise.all([
          this.icdService.retrieveByDeviceId(stockICD.device_id),
          this.mqttCertService.retrieveCAFile(stockICD.flo_ca_version),
          stockICD
        ]);
      })
      .then(([{ Items }, caFile, stockICD]) => {

        if (Items.some(({ is_paired }) => is_paired)) {
          return Promise.reject(new DeviceAlreadyPairedException());
        } 

        return Promise.all([
          this._createPairingData(stockICD, caFile),
          this.issuePairingPermission(userId, stockICD.device_id)
        ]);        
      })
      .then(([qrResponse]) => qrResponse);
  }

  scanQRCode(userId, qrData) {

    return this.ensureUserUniquePairing(userId)
      .then(() => {
        return this.initPairing(userId, qrData);
      });
  }

  retrievePairingsByUserId(userId) {
    return this.authorizationService.retrieveUserResources(userId, 'Location')
      .then(locationIds => 
        Promise.all(
          locationIds.map(locationId => this.icdService.retrieveByLocationId(locationId))
        )
      )
      .then(results => 
        _.chain(results)
          .map(({ Items }) => Items)
          .flatten()
          .value()
      );
  }

  issuePairingPermission(userId, deviceId) {
    return this.pairingPermissionTable.create(TPairingPermission.create({
      user_id: userId,
      device_id: deviceId
    }));
  }

  _createPairingData(stockICD, caFile) {
    return TPairingData.create({
      id: stockICD.id,
      ap_name: stockICD.wifi_ssid,
      ap_password: stockICD.wifi_password,
      device_id: stockICD.device_id,
      login_token: stockICD.icd_login_token,
      client_cert: stockICD.icd_client_cert,
      client_key: stockICD.icd_client_key,
      server_cert: caFile.toString('base64'),
      websocket_cert: stockICD.icd_websocket_cert,
      websocket_cert_der: stockICD.icd_websocket_cert_der || null,
      websocket_key: stockICD.icd_websocket_key
    });
  }

  retrievePairingDataByICDId(icdId) {
    return this.icdService.retrieve(icdId)
      .then(({ Item: icd }) => {
        if (_.isEmpty(icd)) {
          return Promise.reject(new NotFoundException());
        }

        return this.stockICDService.retrieveByDeviceId(icd.device_id);
      })
      .then(stockICD => {
        
        if (!stockICD) {
          return Promise.reject(new NotFoundException());
        }

        return this.mqttCertService.retrieveCAFile(stockICD.flo_ca_version)
          .then(caFile => this._createPairingData(stockICD, caFile));
      });
  }

  unpairDevice(icdId) {
    return this.icdService.remove(icdId)
      .then(() => true);
  }

  completePairing(icdId, deviceId, timezone, userId, appUsed) {
    return this.icdService.retrieve(icdId)
      .then(({ Item: icd }) => {
        if (_.isEmpty(icd)) {
          return Promise.reject(new NotFoundException());
        } else if (icd.isPaired) {
          return Promise.reject(new ConflictException('Device already paired.'));
        }

        return this.deviceSystemModeService.enableForcedSleep(icdId, { user_id: userId, app_used: appUsed })
        .catch(err => {
          // Forced sleep errors should be non-fatal
          this.logger.error({ err });
          return Promise.resolve();
        });
      });
  }
}

export default new DIFactory(PairingService, [StockICDService, MQTTCertService, PairingPermissionTable, ICDService, AuthorizationService, DeviceSystemModeService, Logger]);
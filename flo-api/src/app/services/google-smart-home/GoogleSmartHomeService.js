import _ from 'lodash';
import moment from 'moment';
import config from '../../../config/config';
import ClientType from '../../../util/ClientType';
import DIFactory from '../../../util/DIFactory';
import AlertsService from '../alerts/AlertsService';
import DeviceStateService from '../device-state/DeviceStateService';
import DeviceSystemModeService from '../device-system-mode/DeviceSystemModeService';
import DirectiveService from '../directives/DirectiveService';
import InfoService from '../info/InfoService';
import LogoutService from '../logout/LogoutService';
import NotFoundException from '../utils/exceptions/NotFoundException';
import DeviceOfflineException from './models/exceptions/DeviceOfflineException';
import floAlertSeverities from './models/floAlertSeverities';
import floAlertSeverityEnum from './models/floAlertSeverityEnum';
import floDeviceSystemMode from './models/floDeviceSystemMode';
import floLeakAlertsIds from './models/floLeakAlertsIds';
import googleHomeDeviceTrait from './models/googleHomeDeviceTrait';
import googleHomeDeviceType from './models/googleHomeDeviceType';
import googleHomeErrorResponseTypes from './models/googleHomeErrorResponseTypes';
import googleHomeExecuteCommandStatus from './models/googleHomeExecuteCommandStatus';
import googleHomeFloDeviceSystemMode from './models/googleHomeFloDeviceSystemMode';
import googleHomeIntent from './models/googleHomeIntent';
import googleHomeTraitCommand from './models/googleHomeTraitCommand';
import googleHomeWaterLeakStatus from './models/googleHomeWaterLeakStatus';

class GoogleSmartHomeService {
  constructor(directiveService, deviceSystemModeService, infoService, alertsService, logoutService, deviceStateService, googleSmartHomeConfig, httpClient) {
    this.deviceSystemModeService = deviceSystemModeService;
    this.directiveService = directiveService;
    this.infoService = infoService;
    this.alertsService = alertsService;
    this.logoutService = logoutService;
    this.deviceStateService = deviceStateService;
    this.googleSmartHomeConfig = googleSmartHomeConfig;
    this.httpClient = httpClient;
  }

  processIntentRequest(intent_request, user_id, tokenMetadata) {
    const response = _.map(intent_request.inputs, (input) => {
      switch (input.intent) {
        case googleHomeIntent.disconnect:
          return this._handleDISCONNECT(tokenMetadata)
            .then(() => ({}));
        case googleHomeIntent.execute:
          return this._handleEXECUTE(input, user_id, intent_request.requestId);
        case googleHomeIntent.query:
          return this._handleQuery(intent_request, user_id);
        case googleHomeIntent.sync:
          return this._handleSYNC(intent_request, user_id);
      }
    })
    .map(promise => promise
      .catch(err => this._handleIntentRequestError(err, intent_request, user_id))
    );

    return Promise.all(response);
  }

  _handleIntentRequestError(err, intent_request, user_id) {
    const intentRequestId = intent_request.requestId;

    if (err instanceof NotFoundException) {
      return this._generateErrorResponse(googleHomeErrorResponseTypes.deviceNotFound, intentRequestId, user_id);
    } else if (err instanceof DeviceOfflineException) {
      return this._generateErrorResponse(googleHomeErrorResponseTypes.deviceOffline, intentRequestId, user_id, err.data);
    } else {
      return Promise.reject(err);
    }
  }

  _getSystemModeEnum(mode) {
    switch (mode) {
      case googleHomeFloDeviceSystemMode.home:
        return floDeviceSystemMode.home;
      case googleHomeFloDeviceSystemMode.away:
        return floDeviceSystemMode.away;
      case googleHomeFloDeviceSystemMode.sleep:
        return floDeviceSystemMode.sleep;
    }
  }

  _handleDISCONNECT(tokenMetadata) {
    if (tokenMetadata) {
      const { token_id, user_id, client_id } = tokenMetadata;

      return Promise.all([
        this.logoutService.logout(token_id, user_id, client_id),
        this.deviceStateService.deleteDeviceState(user_id, client_id)
      ]);
    } else {

      return Promise.resolve();
    }
  }

  _handleEXECUTE(input, user_id, id) {
    const processedCommands = _.map(input.payload.commands, (cmd) => {
      const executedCommands = _.map(cmd.execution, (executeCmd) => {
        switch (executeCmd.command) {
          case  googleHomeTraitCommand.modes:
            const smEnum = this._getSystemModeEnum(executeCmd.params.updateModeSettings.mode);
            return this._switchSystemModeAction(user_id, smEnum)
              .then(results => {
                return this._getSystemModeActionResponse(results, id, user_id, executeCmd.params.updateModeSettings.mode);
              });
          case googleHomeTraitCommand.onOff:
            if (executeCmd.params.on) {
              return this._openValveAction(user_id)
                .then(results => {
                  return this._getValveActionResponse(results, user_id, id, 'open');
                });
            }
            else {
              return this._closeValveAction(user_id)
                .then(results => {
                  return this._getValveActionResponse(results, user_id, id, 'close');
                });
            }
          case googleHomeTraitCommand.openClose:
            if (!executeCmd.challenge) {
              return this._generateErrorResponse(googleHomeErrorResponseTypes.challengeNeeded, id, user_id);
            }
            else {
              return this._executeOpenCloseCommand(executeCmd.challenge.ack, executeCmd.params.openPercent, user_id, id);
            }
        }
      });
      return Promise.all(executedCommands)
        .then(executedCommandsResults => {
          return executedCommandsResults[0];
        })
    });
    return Promise.all(processedCommands)
      .then(processedCommandsResults => {
        return processedCommandsResults[0];
      })
  }

  _executeOpenCloseCommand(ack, openPercent, user_id, id) {
    if (ack) {

      if (openPercent >= 100) {
        return this._openValveAction(user_id)
          .then(results => {
            return this._getValveActionResponse(results, user_id, id, 'open');
          });
      }
      else {
        return this._closeValveAction(user_id)
          .then(results => {
            return this._getValveActionResponse(results, user_id, id, 'close');
          });
      }
    }
    else {
      return this._generateErrorResponse(googleHomeErrorResponseTypes.userCancelled, id, user_id);
    }
  }

  _generateErrorResponse(errorResponseType, intentRequestId, userId, metadata) {
    switch (errorResponseType) {
      case googleHomeErrorResponseTypes.challengeNeeded:
        return this._generateChallengeNeededErrorResponse(intentRequestId, userId);
      case googleHomeErrorResponseTypes.deviceJammingDetected:
        return this._generateDeviceJammingDetectedErrorResponse(intentRequestId, userId);
      case googleHomeErrorResponseTypes.deviceNotFound:
        return this._generateDeviceNotFoundErrorResponse(intentRequestId);
      case googleHomeErrorResponseTypes.deviceOffline:
        return this._generateDeviceOfflineErrorResponse(intentRequestId, metadata);
      case googleHomeErrorResponseTypes.userCancelled:
      default:
        return this._generateUserCancelledErrorResponse(intentRequestId, userId);
    }
  }

  _generateDeviceJammingDetectedErrorResponse(intentRequestId, userId) {
    return this._getDefaultIcdDid(userId)
      .then(did => {
        return {
          requestId: intentRequestId,
          payload: {
            commands: [{
              ids: [did],
              status: googleHomeExecuteCommandStatus.error,
              errorCode: googleHomeErrorResponseTypes.deviceJammingDetected,
            }]
          }
        };
      });
  }

  _generateChallengeNeededErrorResponse(intentRequestId, userId) {
    return this._getDefaultIcdDid(userId)
      .then(did => {

        if (!did) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }

        return {
          requestId: intentRequestId,
          payload: {
            commands: [{
              ids: [did],
              status: googleHomeExecuteCommandStatus.error,
              errorCode: googleHomeErrorResponseTypes.challengeNeeded,
              challengeNeeded: {
                type: 'ackNeeded'
              }
            }]
          }
        };
      });
  }

  _generateDeviceNotFoundErrorResponse(intentRequestId) {
    return {
      requestId: intentRequestId,
      payload: {
        errorCode: googleHomeErrorResponseTypes.deviceNotFound
      }
    };
  }

  _generateDeviceOfflineErrorResponse(intentRequestId, metadata) {
    const deviceId = metadata && metadata.deviceId;

    return {
      requestId: intentRequestId,
      payload: {
        ...(
          // Determine if there's enough context to reply with a device-specific
          // error, if not respond with a global error
          deviceId ?
            {
              devices: {
                [deviceId]: {
                  errorCode: googleHomeErrorResponseTypes.deviceOffline
                }
              }
            } :
            {
              errorCode: googleHomeErrorResponseTypes.deviceOffline
            }
        )
      }
    };
  }

  _generateUserCancelledErrorResponse(intentRequestId, userId) {
    return this._getDefaultIcdDid(userId)
      .then(did => {
        return {
          requestId: intentRequestId,
          payload: {
            commands: [{
              ids: [did],
              status: googleHomeExecuteCommandStatus.error,
              errorCode: googleHomeErrorResponseTypes.userCancelled
            }]
          }
        };
      });
  }

  _getSystemModeActionResponse(directiveResult, id, user_id, mode) {
    return this._getLastKnownTelemetry(user_id)
      .then(telemetry => {
        return {
          requestId: id,
          payload: {
            commands: [{
              ids: [telemetry.did],
              status: googleHomeExecuteCommandStatus.success,
              states: {
                online: telemetry.online,
                currentModeSettings: {
                  mode: mode,
                },
                openPercent: telemetry.openPercent
              }
            }]
          }
        };
      });
  }

  _getValveActionResponse(directiveResult, user_id, id, actionType) {
    return this._getLastKnownTelemetry(user_id)
      .then(telemetry => {
        return {
          requestId: id,
          payload: {
            commands: [{
              ids: [telemetry.did],
              status: directiveResult.id !== undefined ? googleHomeExecuteCommandStatus.success : googleHomeExecuteCommandStatus.error,
              states: {
                online: telemetry.online,
                openPercent: telemetry.openPercent
              }
            }]
          }
        }
      });
  }

  _handleQuery(intent_request, user_id) {
    return this._getLastKnownTelemetry(user_id)
      .then(telemetry => {
        if (telemetry.openPercent < 0) {
          return this._generateErrorResponse(googleHomeErrorResponseTypes.deviceJammingDetected, intent_request.requestId, user_id);
        }
        else {
          return {
            requestId: intent_request.requestId,
            payload: {
              agentUserId: user_id,
              devices: {
                [telemetry.did]: telemetry
              }
            }
          }
        }
      });
  }

  _getCurrentModeSettingsFromTelemetry(telemetry) {
    return {mode: this._getSystemModeFromInt(telemetry.systemMode)}
  }

  _getSystemModeFromInt(sm) {
    switch (sm) {
      case 2:
        return googleHomeFloDeviceSystemMode.home;
      case 3:
        return googleHomeFloDeviceSystemMode.away;
      case 5:
        return googleHomeFloDeviceSystemMode.sleep;
    }
  }

  _handleSYNC(intent_request, user_id) {
    return this._getUserDefaultFloDevice(user_id)
      .then(floDevice => {
        return (
            floDevice ?
              this._getLastKnownTelemetryForDevice(floDevice, user_id) :
              Promise.resolve()
          )
          .then(telemetry =>
            telemetry && this.setInitialState(telemetry)
              .then(() => telemetry)
          )
          .then(telemetry => {
            return {
              requestId: intent_request.requestId,
              payload: {
                agentUserId: user_id,
                devices: !floDevice ? [] : [
                  {
                    id: floDevice.device_id,
                    type: googleHomeDeviceType.valve,
                    traits: [
                      googleHomeDeviceTrait.mode,
                      googleHomeDeviceTrait.sensorState,
                      googleHomeDeviceTrait.openClose
                    ],
                    name: {
                      defaultNames: ['Flo Device'],
                      name: 'Flo Device',
                      nicknames: ['Flo Device']
                    },
                    willReportState: true,
                    customData: telemetry || { online: false },
                    deviceInfo: {
                      manufacturer: 'Flo Technologies',
                      model: 'Flo Device'
                    },
                    attributes: {
                      sensorStatesSupported:
                        [
                          {
                            name: 'WaterLeak',
                            descriptiveCapabilities: {
                              availableStates: [googleHomeWaterLeakStatus.leak, googleHomeWaterLeakStatus.noLeak],
                              trackHistory: false
                            }
                          }
                        ],
                      availableModes: [{
                        name: 'mode',
                        name_values: [{
                          name_synonym: ['mode'],
                          lang: 'en',
                        }],
                        settings: [{
                          setting_name: googleHomeFloDeviceSystemMode.home,
                          setting_values: [{
                            setting_synonym: [googleHomeFloDeviceSystemMode.home],
                            lang: 'en'
                          }]
                        },
                          {
                            setting_name: googleHomeFloDeviceSystemMode.away,
                            setting_values: [{
                              setting_synonym: [googleHomeFloDeviceSystemMode.away],
                              lang: 'en'
                            }]
                          },
                          {
                            setting_name: googleHomeFloDeviceSystemMode.sleep,
                            setting_values: [{
                              setting_synonym: [googleHomeFloDeviceSystemMode.sleep],
                              lang: 'en'
                            }]
                          }
                        ],
                        ordered: false
                      }]
                    }
                  }
                ]
              }
            }
          });
      });
  }

  _getPendingAlerts(icdId) {
    return this.httpClient({
      method: 'GET',
      url: `${config.notificationApiUrl}/events`,
      params: {
        deviceId: icdId,
        status: 'triggered',
        severity: 'warning',
        pageSize: 100
      }
    })
    .then(response => response.data)
    .catch(() => ({
      total: 0,
      items: []
    }));
  }

  _getSensorStatusNameFromAlerts(alertResults) {
    if (alertResults.total === 0) {
      return floAlertSeverities.NoAlerts;
    }
    else {
      const alerts = _.sortBy(alertResults.items, (alert) => {
        return alert.severity
      });
      return this._getAlertSensorStateBySeverity(alerts);
    }
  }

  _getAlertSensorStateBySeverity(alerts) {
    switch (alerts[0].severity) {
      case floAlertSeverityEnum.Critical:
        return floAlertSeverities.Critical;
      case floAlertSeverityEnum.Warning:
        return floAlertSeverities.Warning;
      case floAlertSeverityEnum.Info:
      default:
        return floAlertSeverities.NoAlerts;
    }
  }

  _getAlertSensorStatus(icdId) {
    return this._getPendingAlerts(icdId)
      .then(results => {
        return [
          {
            name: 'WaterLeak',
            currentSensorState: this._getWaterLeakStatusFromAlerts(results)
          }
        ];
      });
  }

  _getWaterLeakStatusFromAlerts(alertResults) {
    if (alertResults.total === 0) {
      return googleHomeWaterLeakStatus.noLeak;
    }
    const leakPresent = _.find(alertResults.items, (item) => 
      item.alarm.id === floLeakAlertsIds.smallDripDetected1 ||
      item.alarm.id === floLeakAlertsIds.smallDripDetected2 || 
      item.alarm.id === floLeakAlertsIds.smallDripDetected3 ||
      item.alarm.id === floLeakAlertsIds.smallDripDetected4
    );

    return leakPresent ? 
      googleHomeWaterLeakStatus.leak :
      googleHomeWaterLeakStatus.noLeak;
  }

  _getUserDefaultFloDevice(userId) {
    return this._getUserInfo(userId)
      .then(userInfo => {
        return _.find(userInfo.devices, (d) => d.device_type !== 'puck_oem');
      });
  }

  _getOpenCloseState(telemetry) {
    switch (telemetry.valveState) {
      case 1:
        return 100;
      case  0:
        return 0;
      case 2:
        return 50;
      default:
        return -1;
    }

  }

  _getLastKnownTelemetry(user_id) {
    return this._getUserDefaultFloDevice(user_id)
      .then(floDevice => {
        if (floDevice) {
          return Promise.all([
            this._getLastKnownTelemetryForDevice(floDevice, user_id),
            floDevice
          ]);
        } else {
          return Promise.reject(new NotFoundException('Device not found'));
        }
      })
      .then(([telemetry, floDevice]) => {
        if (!telemetry || !telemetry.online) {
          return Promise.reject(new DeviceOfflineException(floDevice.device_id));
        } else {
          return telemetry;
        }
      });
  }

  _getLastKnownTelemetryForDevice(floDevice) {
    const eventualTelemetry = this.httpClient({
      method: 'GET',
      url: `${config.waterMeterUrl}/latest`,
      params: {
        macAddress: floDevice.device_id
      }
    })
    .then(response => (response.data && _.head(response.data.devices)));

    const eventualIsDeviceConnected = this.httpClient({
      method: 'GET',
      url: `${config.deviceHeartbeatUrl}/state/${floDevice.device_id}`  
    })
    .then(response => response.data && (_.isBoolean(response.data.isConnected) ? response.data.isConnected : true));

    return Promise.all([eventualTelemetry, eventualIsDeviceConnected])
      .then(([deviceTelemetry, isDeviceConnected]) => {
        return deviceTelemetry && this._getTelemetryForGoogleHome(deviceTelemetry, isDeviceConnected, floDevice)
      });
  }

  _getTelemetryForGoogleHome(telemetry, isDeviceConnected, floDevice) {
    return this._getAlertSensorStatus(floDevice.id)
      .then(status => {
        return {
          time: telemetry.timestamp,
          sm: telemetry.systemMode,
          v: telemetry.valveState,
          did: floDevice.device_id,
          online: isDeviceConnected,
          currentModeSettings: this._getCurrentModeSettingsFromTelemetry(telemetry),
          currentSensorStateData: status,
          openPercent: this._getOpenCloseState(telemetry)
        };
      });
  }

  setInitialState(telemetry) {
    return this.deviceStateService.setInitialState('GoogleSmartHome', telemetry);
  }

  _getUserInfo(userId) {
    return this
      .infoService
      .users
      .retrieveByUserId(userId)
      .then(({items: [userInfo]}) => userInfo);
  }

  _getDefaultIcdDid(userId) {
    return this
      ._getUserInfo(userId)
      .then(userInfo => {
        const maybeDevice = userInfo.devices && userInfo.devices.length ? 
          _.find(userInfo.devices, (d) => d.device_type !== 'puck_oem') : 
          null;

        return maybeDevice ? maybeDevice.device_id : null;
      });
  }

  _getDefaultIcdId(userId) {
    return this
      ._getUserInfo(userId)
      .then(userInfo => {
        const maybeDevice = userInfo.devices && userInfo.devices.length ? 
          _.find(userInfo.devices, (d) => d.device_type !== 'puck_oem') : 
          null;

        return maybeDevice ? maybeDevice.id : null;
      });
  }

  _switchValveAction(userId, toValveState) {
    return this._getDefaultIcdId(userId)
      .then(icdId => {

        if (!icdId) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }

        return this.directiveService
          .sendDirective(
            `${toValveState}-valve`,
            icdId,
            userId,
            ClientType.OTHER,
            {}
          ).then(([notUsed, kafkaDirectiveData]) => {
            return {
              id: kafkaDirectiveData.directive_id
            };
          });
      });
  }

  _switchSystemModeAction(userId, mode) {
    return this._getDefaultIcdId(userId)
      .then(icdId => {
        if (!icdId) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }

        if (mode !== floDeviceSystemMode.sleep) {
          return this.directiveService
            .sendDirective(
              'set-system-mode',
              icdId,
              userId,
              ClientType.OTHER,
              {
                mode: mode
              }
            ).then(([notUsed, kafkaDirectiveData]) => {
              return {
                id: kafkaDirectiveData.directive_id
              };
            });
        }
        else {
          return this._getLastKnownTelemetry(userId)
            .then(telemetry => {
              const twoHrs = 120;
              return this.deviceSystemModeService.sleep(icdId, telemetry.sm, twoHrs, {
                user_id: userId,
                app_used: ClientType.OTHER
              })
            })
        }
      });
  }

  _openValveAction(userId) {
    return this._switchValveAction(userId, 'open');
  }

  _closeValveAction(userId) {
    return this._switchValveAction(userId, 'close');
  }
}

export default DIFactory(
  GoogleSmartHomeService,
  [DirectiveService, DeviceSystemModeService, InfoService, AlertsService, LogoutService, DeviceStateService, 'GoogleSmartHomeConfig', 'HttpClient']);

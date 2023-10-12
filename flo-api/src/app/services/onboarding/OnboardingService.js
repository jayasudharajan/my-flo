import _ from 'lodash';
import uuid from 'uuid';
import ICDService from '../icd-v1_5/ICDService';
import DIFactory from '../../../util/DIFactory';
import NotFoundException from '../utils/exceptions/NotFoundException';
import TOnboardingEvent from './models/TOnboardingEvent';
import OnboardingLogTable from './OnboardingLogTable';
import KafkaProducer from '../utils/KafkaProducer';
import AlertService from './AlertService';

class OnboardingService {

  constructor(config, icdService, onboardingLogTable, kafkaProducer, mqttClient) {
    this.config = config;
    this.icdService = icdService;
    this.onboardingLogTable = onboardingLogTable;
    this.kafkaProducer = kafkaProducer;
    this.alertService = new AlertService(config, kafkaProducer);
    this.mqttClient =  mqttClient;
  }

  _withIcd(deviceId) {
    return this
      .icdService
      .retrieveByDeviceId(deviceId)
      .then(({Items: [icd]}) => {
        if (!icd) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }
        return icd;
      });
  }

  doOnDevicePaired(icdId, locationId) {
    return this.logOnboardingEvent(icdId, TOnboardingEvent.paired);
  }

  doOnDeviceInstalled(deviceId) {
    return this.logOnboardingEventByDeviceId(deviceId, TOnboardingEvent.installed);
  }

  doOnSystemModeUnlocked(icdId) {
    return this.logOnboardingEvent(icdId, TOnboardingEvent.systemModeUnlocked);
  }

  doOnDeviceEvent(eventInfo) {
    const event = TOnboardingEvent[eventInfo.event.name];

    return this
      ._withIcd(eventInfo.device_id)
      .then(icd => {
         return this.isEventUnique(icd.id, event)
           .then(isUnique => [icd, isUnique]);
      })
      .then(([icd, isUnique]) => 
        isUnique ? 
          Promise.all([
            this._logOnboardingEvent(icd.id, event),
            this.reactToEvent(icd.id, eventInfo.device_id, event),
            this.acknowledgeEvent(eventInfo)
          ]) :
          this.acknowledgeEvent(eventInfo)
      )
      .catch(err => this._handleErrors(eventInfo.id, err));
  }

  _handleErrors(request_id, err) {
    if (err instanceof NotFoundException) {
      return Promise.resolve({
        request_id: request_id,
        error_message: 'Device not found'
      });
    } else {
      return Promise.reject(err);
    }
  }

  reactToEvent(icdId, deviceId, event) {
    return this
      .retrieveByIcdId(icdId)
      .then(events => {
        const eventsToCompare = new Set(_.union(events.map(x => x.event), [parseInt(event)]));
        const installedAlertConditions = [TOnboardingEvent.installed, TOnboardingEvent.paired];

        if (_.every(installedAlertConditions, (c) => eventsToCompare.has(parseInt(c)))) {
          return this.alertService.sendAlert(deviceId, this.config.installedAlertId);
        }

        return Promise.resolve({});
      });
  }

  acknowledgeEvent(eventInfo) {
    const ack = {
      id: uuid.v1(),
      device_id: eventInfo.device_id,
      timestamp: new Date().getTime(),
      request_id: eventInfo.id
    };
    return Promise.all([
      this.kafkaProducer.send(this.config.eventsAckTopic, JSON.stringify(ack), true, eventInfo.device_id),
      // TODO: Move this mqtt logic to a MQTT Kafka Connector, for that we need to deploy certs to Connect cluster
      this.mqttClient.publish(`home/device/${eventInfo.device_id}/v1/events/install/ack`, JSON.stringify(ack))
    ]);
  }

  logOnboardingEventByDeviceId(deviceId, event) {
    return this._withIcd(deviceId)
      .then(icd => {
        return this.logOnboardingEvent(icd.id, event);
      });
  }

  logOnboardingEvent(icdId, event) {
    return this.isEventUnique(icdId, event)
      .then(isUnique => {
        if (isUnique) {
          return this._logOnboardingEvent(icdId, event);
        } else {
          return {};
        }
      });
  }

  _logOnboardingEvent(icdId, event) {
    try {
      return this.onboardingLogTable.createLatest({icd_id: icdId, event});
    } catch (err) {
      return Promise.reject(err);
    }
  }

  retrieveCurrentState(icdId) {
    return this.onboardingLogTable.retrieveCurrentState(icdId);
  }

  retrieveByIcdId(icdId) {
    return this.onboardingLogTable.retrieveByIcdId(icdId)
      .then(({Items}) => Items);
  }

  create(onboardingEvent) {
    return this.isEventUnique(onboardingEvent.icd_id, onboardingEvent.event)
        .then(isUnique => {
          if (isUnique) {
            return this.onboardingLogTable.create(onboardingEvent);
          } else {
            return {};
          }
        });
  }

  isEventUnique(icdId, event) {
    return this.onboardingLogTable.retrieveByIcdIdEvent(icdId, event)
      .then(result => _.isEmpty(result));
  }
}

export default new DIFactory(
  OnboardingService, ['OnboardingServiceConfig', ICDService, OnboardingLogTable, KafkaProducer, 'MQTTClient']
);
import _ from 'lodash';
import uuid from 'uuid';
import moment from 'moment';

//TODO: Merge this to the AlertsService in services/alerts. I will not do it now because needs refactor on GoogleHome and we still needs the approval from google
class AlertService {
  constructor(config, kafkaProducer) {
    this.config = config;
    this.kafkaProducer = kafkaProducer;
  }

  _createAlert(deviceId, alarmId) {
    const now = new Date().getTime();
    const incidentId = uuid.v1({
      node: _.chunk(deviceId, 2).map(chars => parseInt(chars.join(''), 16))
    });

    return {
      id: incidentId,
      ts: now,
      did: deviceId,
      data: {
        alarm: {
          ht: now,
          acts: null,
          reason: parseInt(alarmId),
          defer: 0
        },
        snapshot: {
          tz: 'Etc/UTC',
          lt: moment().format('HH:mm:ss'),
          sm: 2,
          f: -1,
          fr: -1,
          t: -1,
          p: -1,
          sw1: 1,
          sw2: 0,
          ef: -1,
          efd: -1,
          ft: -1,
          pmin: -1,
          pmax: -1,
          tmin: -1,
          tmax: -1,
          frl: -1,
          efl: -1,
          efdl: -1,
          ftl: -1
        }
      }
    };
  }

  sendAlert(deviceId, alertId) {
    return this
      .kafkaProducer
      .send(
        this.config.notificationsKafkaTopic,
        JSON.stringify(this._createAlert(deviceId, alertId)), true, deviceId
      );
  }
}

export default AlertService;
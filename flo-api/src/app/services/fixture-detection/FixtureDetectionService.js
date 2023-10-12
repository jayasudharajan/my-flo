import DIFactory from  '../../../util/DIFactory';
import FixtureDetectionLogTable from './FixtureDetectionLogTable';
import TStatus from './models/TStatus';
import KafkaProducer from '../utils/KafkaProducer';
import NotFoundException from '../utils/exceptions/NotFoundException';
import ICDService from '../icd-v1_5/ICDService';
import FixtureDetectionConfig from './FixtureDetectionConfig';
import uuid from 'node-uuid';

class FixtureDetectionService {
  constructor(fixtureDetectionConfig, fixtureDetectionLogTable, icdService, kafkaProducer) {
    this.fixtureDetectionConfig = fixtureDetectionConfig;
    this.fixtureDetectionLogTable = fixtureDetectionLogTable;
    this.icdService = icdService;
    this.kafkaProducer = kafkaProducer;
  }

  _withIcd(deviceId) {
    return this
      .icdService
      .retrieveByDeviceId(deviceId)
      .then(({Items: icds}) => {
        if (!icds || icds.length < 1) {
          return Promise.reject(new NotFoundException('Device not found.'))
        }
        return icds[0];
      });
  }

  _logFixtureStatus(data, status) {
    const params = {
      ...data,
      status: status
    };

    return this.fixtureDetectionLogTable.createLatest(params);
  }

  logFixtureDetection(deviceId, data) {
    return this
      ._withIcd(deviceId)
      .then(() => {
        const detectedFixturesRecord = {
          device_id: deviceId,
          ...data
        };

        return this._logFixtureStatus(detectedFixturesRecord, TStatus.executed);
      });
  }

  retrieveFixtureDetectionResults(deviceId, requestId) {
    return this
      .fixtureDetectionLogTable
      .retrieveLatest({ request_id: requestId })
      .then(({ Items: items }) => {
        if(items.length > 0 && items[0].device_id != deviceId) {
          return Promise.reject(new NotFoundException('Fixture data not found for that request and device id'));
        }

        return this._mapRetrieveResult(items);
      });
  }

  retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate) {
    return this
      .fixtureDetectionLogTable
      .retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate)
      .then(({ Items: items }) => this._mapRetrieveResult(items));
  }

  retrieveLatestByDeviceId(deviceId) {
    return this
      .fixtureDetectionLogTable
      .retrieveLatestByDeviceId(deviceId)
      .then(({ Items: items }) => this._mapRetrieveResult(items));
  }

  updateFixturesWithFeedback(request_id, created_at, fixtures){

    return this
    .fixtureDetectionLogTable
    .patch({request_id, created_at}, { fixtures, status: TStatus.feedback_submitted });
    
  }

  _mapRetrieveResult(items) {
    if(items.length < 1) {
      return Promise.reject(new NotFoundException('Fixture data not found for those parameters'));
    }

    return items[0];
  }

  _runFixturesDetection(deviceId, startDate, endDate) {
    return this
      ._withIcd(deviceId)
      .then(icd => {
        const requestId = uuid.v4();
        const message = {
          request_id: requestId,
          device_id: deviceId,
          icd_id: icd.id,
          start_date: startDate,
          end_date: endDate
        };

        return Promise.all([
          this._logFixtureStatus(message, TStatus.sent),
          this
            .fixtureDetectionConfig
            .fixtureDetectionKafkaTopic()
            .then(topic => this.kafkaProducer.send(topic, JSON.stringify(message), true, deviceId))
        ]).then(() => ({request_id: requestId}));
      });
  }

  runFixturesDetection(deviceId, startDate, endDate) {
    return this
      .fixtureDetectionLogTable
      .retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate)
      .then(({ Items: items }) => {
        if(items.length < 1) {
          return this._runFixturesDetection(deviceId,startDate, endDate);
        }

        return { request_id: items[0].request_id };
      });
  }
}

export default DIFactory(
  FixtureDetectionService,
  [FixtureDetectionConfig, FixtureDetectionLogTable, ICDService, KafkaProducer]
);



import _ from 'lodash';
import DIFactory from  '../../../util/DIFactory';
import FloDetectResultTable from './FloDetectResultTable';
import FloDetectEventChronologyTable from './FloDetectEventChronologyTable';
import FloDetectFixtureAverageTable from './FloDetectFixtureAverageTable';
import TStatus from './models/TStatus';
import NotFoundException from '../utils/exceptions/NotFoundException';
import uuid from 'node-uuid';
import moment from 'moment-timezone';
import OnboardingService from '../onboarding/OnboardingService';
import TOnboardingEvent from '../onboarding/models/TOnboardingEvent';
import ICDService from '../icd-v1_5/ICDService';

class FloDetectService {
  constructor(icdService, onboardingService, floDetectResultTable, floDetectEventChronologyTable, floDetectFixtureAverageTable, config) {
    this.icdService = icdService;
    this.onboardingService = onboardingService;
    this.floDetectResultTable = floDetectResultTable;
    this.floDetectEventChronologyTable = floDetectEventChronologyTable;
    this.floDetectFixtureAverageTable = floDetectFixtureAverageTable;
    this.config = config;
  }

  _logFixtureStatus(data, status) {
    const params = {
      ...data,
      status: status
    };

    return this.floDetectResultTable.create(params);
  }

  logFloDetect(deviceId, data) {
 
    const detectedFixturesRecord = {
      device_id: deviceId,
      ...data
    };

    return this._logFixtureStatus(detectedFixturesRecord, data.status || TStatus.executed);
  }

  _shouldInstallDateQualify(deviceId) {
    return this.icdService.retrieveByDeviceId(deviceId)
      .then(({ Items: [icd] }) => {
        if (!icd) {
          return Promise.reject(new NotFoundException('Device not found.'));
        }

        return this.onboardingService.retrieveByIcdId(icd.id);
      })
      .then(onboardingEvents => {

        return onboardingEvents.some(onboardingEvent => 
          onboardingEvent.event >= TOnboardingEvent.installed && 
          moment().diff(onboardingEvent.created_at, 'days', true) >= this.config.floDetectMinimumDaysInstalled
        );
      });
  }

  _ensureDeviceQualification(deviceId, doIfQualified) {

    return this._shouldInstallDateQualify(deviceId)
      .then(isQualified => (
        !isQualified ?
          {
            device_id: deviceId,
            status: TStatus.learning
          } :
          doIfQualified()
      ));
  }

  _withLegacyResult(result) {
    if (result.status != TStatus.executed && result.status != TStatus.feedback_submitted) {
      return Promise.reject(new NotFoundException('Fixture data not found for those parameters'));
    } else {
      return result;
    }  
  }

  _retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate, timezone) {
    return this
      .floDetectResultTable
      .retrieveByDeviceIdAndDateRange({ device_id: device_id, start_date: startDate, end_date: endDate })
      .then(({ Item }) => this._mapRetrieveResult(Item, timezone));
  }

  retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate, timezone) {

    return this._retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate, timezone)
      .then(result => this._withLegacyResult(result));
  }

  retrieveByDeviceIdAndDateRangeWithStatus(deviceId, startDate, endDate, timezone) {
    return this._ensureDeviceQualification(deviceId, () => 
      this._retrieveByDeviceIdAndDateRange(deviceId, startDate, endDate, timezone) 
    );
  }

  _retrieveLatestByDeviceId(deviceId, duration, timezone) {
    return this
      .floDetectResultTable
      .retrieveLatestByDeviceId(deviceId, duration)
      .then(({ Items: items }) => this._mapRetrieveResult(items, timezone));
  }

  retrieveLatestByDeviceId(deviceId, duration, timezone) {
    return this._retrieveLatestByDeviceId(deviceId, duration, timezone)
      .then(result => this._withLegacyResult(result));
  }

  retrieveLatestByDeviceIdWithStatus(deviceId, duration, timezone) {

    return this._ensureDeviceQualification(deviceId, () => 
      this._retrieveLatestByDeviceId(deviceId, duration, timezone)
    );
  }

  _retrieveLatestByDeviceIdInDateRange(deviceId, duration, rangeBegin, rangeEnd, timezone) {
    return this.floDetectResultTable.retrieveLatestByDeviceIdInDateRange(deviceId, duration, rangeBegin, rangeEnd)
      .then(({ Items: items }) => this._mapRetrieveResult(items, timezone))
  }

  retrieveLatestByDeviceIdInDateRange(deviceId, duration, rangeBegin, rangeEnd, timezone) {
    return this._retrieveLatestByDeviceIdInDateRange(deviceId, duration, rangeBegin, rangeEnd, timezone)
      .then(result => this._withLegacyResult(result));
  }

  retrieveLatestByDeviceIdInDateRangeWithStatus(deviceId, duration, rangeBegin, rangeEnd, timezone) {
    
    return this._ensureDeviceQualification(deviceId, () =>
      this._retrieveLatestByDeviceIdInDateRange(deviceId, duration, rangeBegin, rangeEnd, timezone)
    );
  }

  updateFixturesWithFeedback(deviceId, startDate, endDate, fixtures) {
    const keys = this.floDetectResultTable.composeKeys({ 
      device_id: deviceId, 
      start_date: startDate, 
      end_date: endDate 
    });

    return this
    .floDetectResultTable
    .patch(keys, { fixtures, status: TStatus.feedback_submitted });
  }

  updateEventChronologyWithFeedback(deviceId, requestId, startDate, eventFeedback) {
    return this.floDetectEventChronologyTable.patch(
      { 
        device_id: deviceId, 
        request_id: requestId, 
        start: startDate 
      }, 
      {
        feedback: eventFeedback
      },
      'ALL_NEW'
    )
    .then(({ Attributes }) => Attributes);
  }

  retrieveEventChronologyPage(deviceId, requestId, pageSize = 50, startDate, isDescending = false) {
    const start = startDate || (isDescending ? new Date().toISOString() : new Date(0).toISOString());
    
    return this.floDetectEventChronologyTable.retrieveAfterStartDate(deviceId, requestId, start, pageSize, isDescending)
      .then(({ Items }) => Items);
  } 

  batchCreateEventChronology(deviceId, requestId, eventChronologyBatch) {
    const events = eventChronologyBatch.map(event => ({
      ...event,
      device_id: deviceId,
      request_id: requestId
    }));

    return Promise.all(
      _.chunk(events, 25)
        .map(eventBatch => this.floDetectEventChronologyTable.batchCreate(eventBatch))
    )
    .then(() => true);
  }

  _mapRetrieveResult(data, timezone) {
    const items = (_.isArray(data) ? data : [data]).filter(item => !_.isEmpty(item));

    if(items.length < 1) {
      return Promise.reject(new NotFoundException('Fixture data not found for those parameters'));
    }

    const item = items[0];

    return {
      ...item,
      start_date: timezone ? moment(item.start_date).tz(timezone).format() : new Date(item.start_date).toISOString(),
      end_date: timezone ? moment(item.end_date).tz(timezone).format() : new Date(item.end_date).toISOString(),
      ...(
        !item.event_chronology ? 
          {} : 
          {
            event_chronology: item.event_chronology.map(event => ({
            ...event,
            start: timezone ? moment(event.start).tz(timezone).format() : new Date(event.start).toISOString(),
            end: timezone ? moment(event.end).tz(timezone).format() : new Date(event.end).toISOString()
          }))
        }
      )
    };
  }

  logFixtureAverages(data) {
    return this.floDetectFixtureAverageTable.create(data);
  }

  retrieveLatestFixtureAverages(deviceId, duration) {
    return this.floDetectFixtureAverageTable.retrieveLatest(deviceId, duration)
      .then(({ Items = [] }) => Items[0]);
  }
}

export default DIFactory(
  FloDetectService,
  [ICDService, OnboardingService, FloDetectResultTable, FloDetectEventChronologyTable, FloDetectFixtureAverageTable, 'FloDetectConfig']
);


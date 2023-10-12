import FloDetectService from './FloDetectService';
import DIFactory from '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class FloDetectController {
  constructor(floDetectService) {
    this.floDetectService = floDetectService;
  }

  logFloDetect({ params: { device_id }, body }) {
    return this.floDetectService.logFloDetect(device_id, body);
  }

  retrieveByDeviceIdAndDateRange({ params: { device_id, start_date, end_date }, query: { tz } }) {
    return this.floDetectService.retrieveByDeviceIdAndDateRange(device_id, start_date, end_date, tz);
  }

  retrieveByDeviceIdAndDateRangeWithStatus({ params: { device_id, start_date, end_date }, query: { tz } }) {
    return this.floDetectService.retrieveByDeviceIdAndDateRangeWithStatus(device_id, start_date, end_date, tz);
  }

  retrieveLatestByDeviceId({ params: { device_id, duration }, query: { tz } }) {
    return this.floDetectService.retrieveLatestByDeviceId(device_id, parseInt(duration), tz);
  }

  retrieveLatestByDeviceIdWithStatus({ params: { device_id, duration }, query: { tz } }) {
    return this.floDetectService.retrieveLatestByDeviceIdWithStatus(device_id, parseInt(duration), tz);
  }

  runFixturesDetection({ params: { device_id }, body: { start_date, end_date } }) {
    return this.floDetectService.runFixturesDetection(device_id, start_date, end_date);
  }

  updateFixturesWithFeedback({ params: { device_id, start_date, end_date }, body: { fixtures } }) {
    return this.floDetectService.updateFixturesWithFeedback(device_id, start_date, end_date, fixtures);
  }

  retrieveLatestByDeviceIdInDateRange({ params: { device_id, duration, start_date, end_date }, query: { tz } }) {
    return this.floDetectService.retrieveLatestByDeviceIdInDateRange(device_id, duration, start_date, end_date, tz);
  }

  retrieveLatestByDeviceIdInDateRangeWithStatus({ params: { device_id, duration, start_date, end_date }, query: { tz } }) {
    return this.floDetectService.retrieveLatestByDeviceIdInDateRangeWithStatus(device_id, duration, start_date, end_date, tz);
  }
  updateEventChronologyWithFeedback({ params: { device_id, request_id, start_date }, body: feedback }) {
    return this.floDetectService.updateEventChronologyWithFeedback(device_id, request_id, start_date, feedback);
  }

  retrieveEventChronologyPage({ params: { device_id, request_id }, query: { size, start, desc = 'true' } }) {
    return this.floDetectService.retrieveEventChronologyPage(device_id, request_id, size, start, desc == 'true');
  }

  batchCreateEventChronology({ params: { device_id, request_id }, body: { event_chronology: events } }) {
    return this.floDetectService.batchCreateEventChronology(device_id, request_id, events);
  }

  logFixtureAverages({ body: data }) {
    return this.floDetectService.logFixtureAverages(data);
  }

  retrieveLatestFixtureAverages({ params: { device_id, duration } }) {
    return this.floDetectService.retrieveLatestFixtureAverages(device_id, duration);
  }

}

export default new DIFactory(new ControllerWrapper(FloDetectController), [FloDetectService]);
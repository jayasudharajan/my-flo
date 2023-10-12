import FixtureDetectionService from './FixtureDetectionService';
import DIFactory from '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class FixtureDetectionController {
  constructor(fixtureDetectionService) {
    this.fixtureDetectionService = fixtureDetectionService;
  }

  logFixtureDetection({ params: { device_id }, body }) {
    return this.fixtureDetectionService.logFixtureDetection(device_id, body);
  }

  retrieveFixtureDetectionResults({ params: { device_id, request_id } }) {
    return this.fixtureDetectionService.retrieveFixtureDetectionResults(device_id, request_id);
  }

  retrieveByDeviceIdAndDateRange({ params: { device_id, start_date, end_date } }) {
    return this.fixtureDetectionService.retrieveByDeviceIdAndDateRange(device_id, start_date, end_date);
  }

  retrieveLatestByDeviceId({ params: { device_id } }) {
    return this.fixtureDetectionService.retrieveLatestByDeviceId(device_id);
  }

  runFixturesDetection({ params: { device_id }, body: { start_date, end_date } }) {
    return this.fixtureDetectionService.runFixturesDetection(device_id, start_date, end_date);
  }

  updateFixturesWithFeedback({params: { request_id, created_at }, body: {fixtures} }) {
    return this.fixtureDetectionService.updateFixturesWithFeedback(request_id, created_at,fixtures);
  }
}

export default new DIFactory(new ControllerWrapper(FixtureDetectionController), [FixtureDetectionService]);
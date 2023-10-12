import DIFactory from  '../../../util/DIFactory';
import AwayModeService from './AwayModeService';
import { ControllerWrapper } from '../../../util/controllerUtils';

class AwayModeController {
  constructor(awayModeService) {
    this.awayModeService = awayModeService;
  }

  retrieveIrrigationSchedule({ params: { icd_id } }) {
    return this.awayModeService.retrieveIrrigationSchedule(icd_id);
  }

  enableDeviceAwayMode({ app_used, token_metadata: { user_id }, params: { icd_id }, body: { times } }) {
    return this.awayModeService.enableDeviceAwayMode(icd_id, times, user_id, app_used);
  }

  disableDeviceAwayMode({ app_used, token_metadata: { user_id }, params: { icd_id } }) {
    return this.awayModeService.disableDeviceAwayMode(icd_id, user_id, app_used);
  }

  retrieveAwayModeState({ params: { icd_id } }) {
    return this.awayModeService.retrieveAwayModeState(icd_id);
  }
}

export default new DIFactory(ControllerWrapper(AwayModeController), [AwayModeService]);
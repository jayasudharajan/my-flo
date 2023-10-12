import DeviceSystemModeService from './DeviceSystemModeService';
import DIFactory from '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class DeviceSystemModeController {
  constructor(deviceSystemModeService) {
    this.deviceSystemModeService = deviceSystemModeService;
  }

  setSystemMode({ app_used, params: { icd_id }, body: { system_mode }, token_metadata: { user_id } }) {
    return this.deviceSystemModeService.setSystemMode(icd_id, system_mode, { app_used, user_id });
  }

  disableForcedSleep({ app_used, params: { icd_id }, token_metadata: { user_id } }) {
    return this.deviceSystemModeService.disableForcedSleep(icd_id, { app_used, user_id });
  }

  enableForcedSleep({ app_used, params: { icd_id }, token_metadata: { user_id } }) {
    return this.deviceSystemModeService.enableForcedSleep(icd_id, { app_used, user_id });
  }

  sleep({ app_used, params: { icd_id }, body: { sleep_minutes, wake_up_system_mode }, token_metadata: { user_id } }) {
    return this.deviceSystemModeService.sleep(icd_id, wake_up_system_mode, sleep_minutes, { app_used, user_id });
  }
}

export default new DIFactory(new ControllerWrapper(DeviceSystemModeController), [DeviceSystemModeService]);
import OnboardingService from './OnboardingService'
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class OnboardingController {

  constructor(onboardingService) {
    this.onboardingService = onboardingService;
  }

  doOnDevicePaired({ body: { id: icd_id, location_id }}, res, next) {
    return this.onboardingService.doOnDevicePaired(icd_id, location_id);
  }

  doOnDeviceInstalled({ body: { device_id }}, res, next) {
    return this.onboardingService.doOnDeviceInstalled(device_id);
  }

  doOnSystemModeUnlocked({ body: { icd_id }}, res, next) {
    return this.onboardingService.doOnSystemModeUnlocked(icd_id);
  }

  doOnDeviceEvent({ body }, res, next) {
    return this.onboardingService.doOnDeviceEvent(body);
  }

  retrieveCurrentState({ params: { icd_id } }, res, next) {
    return this.onboardingService.retrieveCurrentState(icd_id);
  }
}

export default new DIFactory(new ControllerWrapper(OnboardingController), [ OnboardingService ]);
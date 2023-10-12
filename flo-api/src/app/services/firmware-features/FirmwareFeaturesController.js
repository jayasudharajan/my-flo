import FirmwareFeaturesService from './FirmwareFeaturesService'
import DIFactory from '../../../util/DIFactory';
import {ControllerWrapper} from '../../../util/controllerUtils';

class FirmwareFeaturesController {

  constructor(firmwareFeaturesService) {
    this.firmwareFeaturesService = firmwareFeaturesService;
  }

  retrieveVersionFeatures({ params: { version } }) {
    return this.firmwareFeaturesService.retrieveVersionFeatures(version);
  }

}

export default new DIFactory(new ControllerWrapper(FirmwareFeaturesController), [FirmwareFeaturesService]);

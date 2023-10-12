import InsuranceLetterService from './InsuranceLetterService'
import DIFactory from '../../../util/DIFactory';
import {ControllerWrapper} from '../../../util/controllerUtils';

class InsuranceLetterController {

  constructor(insuranceLetterService) {
    this.insuranceLetterService = insuranceLetterService;
  }

  generate({ body: { location_id }, token_metadata: { user_id } }) {
    return this.insuranceLetterService.generate(location_id, user_id);
  }

  regenerate({ body: { location_id }, token_metadata: { user_id } }) {
    return this.insuranceLetterService.regenerate(location_id, user_id);
  }

  getDownloadInfo({ params: { location_id } }) {
    return this.insuranceLetterService.getDownloadInfo(location_id);
  }

  redeem({ body: { location_id }, token_metadata: { user_id } }) {
    return this.insuranceLetterService.redeem(location_id, user_id);
  }
}

export default new DIFactory(new ControllerWrapper(InsuranceLetterController), [InsuranceLetterService]);

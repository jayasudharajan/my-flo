import DIFactory from '../../../util/DIFactory';
import {ControllerWrapper} from '../../../util/controllerUtils';
import GoogleSmartHomeService from './GoogleSmartHomeService';


class GoogleSmartHomeController {
  constructor(googleSmartHomeService) {
    this.googleSmartHomeService = googleSmartHomeService;
  }

  processIntentRequest({body, token_metadata }) {
    const { user_id } = token_metadata;
    
    return this.googleSmartHomeService.processIntentRequest(body, user_id, token_metadata)
      .then(response => {
        return response[0];
      });
  }
}

export default new DIFactory(new ControllerWrapper(GoogleSmartHomeController), [GoogleSmartHomeService]);
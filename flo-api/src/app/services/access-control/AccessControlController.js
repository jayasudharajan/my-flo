import AccessControlService from './AccessControlService';
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class AccessControlController {
  constructor(aclService) {
    this.aclService = aclService;
  }

  authorize({ token_metadata, body: { method_id, params } }) {
    return this.aclService.authorize(token_metadata, method_id, params);
  }

  refreshUserRoles({ body: { user_id } }) {
    return this.aclService.refreshUserRoles(user_id)
      .then(() => ({}));
  }

}

export default new DIFactory(new ControllerWrapper(AccessControlController), [AccessControlService]);

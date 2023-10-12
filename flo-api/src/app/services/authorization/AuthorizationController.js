import AuthorizationService from './AuthorizationService';
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class AuthorizationController {
  constructor(authorizationService) {
    this.authorizationService = authorizationService;
  }

  retrieveUserAccountGroupRolesByGroupId({ params: { group_id } }) {
    return this.authorizationService.retrieveUserAccountGroupRolesByGroupId(group_id);
  }

  retrieveUserAccountGroupRolesByUserId({ params: { user_id } }) {
    return this.authorizationService.retrieveUserAccountGroupRolesByUserId(user_id);
  }
}

export default new DIFactory(new ControllerWrapper(AuthorizationController), [ AuthorizationService ]);

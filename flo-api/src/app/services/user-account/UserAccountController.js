import UserAccountService from './UserAccountService';
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class UserAccountController {
	constructor(userAccountService) {
		this.userAccountService = userAccountService;
	}

	createNewUserAndAccount({ body: userData }) {
		return this.userAccountService.createNewUserAndAccount(userData);
	}

  removeUserAndAccount({ params: { user_id, account_id, location_id } }) {
    return this.userAccountService.removeUserAndAccount(user_id, account_id, location_id);
  }
}

export default new DIFactory(new ControllerWrapper(UserAccountController), [UserAccountService]);
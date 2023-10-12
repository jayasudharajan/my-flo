import AccountService from './AccountService'
import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';

class AccountController extends CrudController {

  constructor(accountService) {
    super(accountService.accountTable);
    this.accountService = accountService;
  }

  retrieveByGroupId({ params: { group_id } }) {
  	return this.accountService.retrieveByGroupId(group_id);
  }

  retrieveByOwnerUserId({ params: { owner_user_id } }) {
  	return this.accountService.retrieveByOwnerUserId(owner_user_id);
  }
}

export default new DIFactory(new ControllerWrapper(AccountController), [ AccountService ]);
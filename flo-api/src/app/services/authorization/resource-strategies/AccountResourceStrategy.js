import ResourceStrategy from './ResourceStrategy';
import UserAccountRoleTable from '../UserAccountRoleTable';
import DIFactory from  '../../../../util/DIFactory';

class AccountResourceStrategy extends ResourceStrategy {
	constructor(userAccountRoleTable) {
		super('Account', 'account_id', userAccountRoleTable);
	}
}

export default new DIFactory(AccountResourceStrategy, [UserAccountRoleTable]);
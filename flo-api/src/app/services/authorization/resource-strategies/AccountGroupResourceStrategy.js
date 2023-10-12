import ResourceStrategy from './ResourceStrategy';
import UserAccountGroupRoleTable from '../UserAccountGroupRoleTable';
import DIFactory from  '../../../../util/DIFactory';

class AccountGroupResourceStrategy extends ResourceStrategy {
	constructor(userAccountGroupRoleTable) {
		super('AccountGroup', 'group_id', userAccountGroupRoleTable);
	}

  retrieveUserRolesByGroupId(groupId) {
    return this.subResourceTable.retrieveByGroupId(groupId)
      .then(({ Items }) => Items);
  }

  retrieveUserRolesByUserId(userId) {
    return this.subResourceTable.retrieveByUserId(userId)
      .then(({ Items }) => Items);
  }
}

export default new DIFactory(AccountGroupResourceStrategy, [UserAccountGroupRoleTable]);
import ResourceStrategy from './ResourceStrategy';
import UserSystemRoleTable from '../UserSystemRoleTable';
import DIFactory from  '../../../../util/DIFactory';

class SystemResourceStrategy extends ResourceStrategy {
	constructor(userSystemRoleTable) {
		super('system', undefined, userSystemRoleTable);

		this.userSystemRoleTable = userSystemRoleTable;
	}

	getSubResourceRolesByUserId(userId) {
		return this.userSystemRoleTable.retrieve({ user_id: userId })
			.then(({ Item }) => 
				!Item ?
					[] :
					Item.roles.map(role => `system.${ role }`)
			);
	}

}

export default new DIFactory(SystemResourceStrategy, [UserSystemRoleTable]);
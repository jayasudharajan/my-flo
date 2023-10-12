import SystemUserDetailTable from './SystemUserDetailTable';
import DIFactory from  '../../../util/DIFactory';

class SystemUserService {
	constructor(systemUserDetailTable) {
		this.systemUserDetailTable = systemUserDetailTable;
	}

	retrieveDetail(userId) {
		return this.systemUserDetailTable.retrieve({ user_id: userId })
			.then(({ Item }) => Item);
	}
}

export default new DIFactory(SystemUserService, [SystemUserDetailTable]);
import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import AccountTable from './AccountTable';
import DIFactory from  '../../../util/DIFactory';
import TLocation from '../location-v1_5/models/TLocation';
import uuid from 'uuid';

class AccountService {

	constructor(accountTable) {
		this.accountTable = accountTable;
	}
	
  retrieve(accountId) {
		return this.accountTable.retrieve(accountId);
	}

	update(data) {
		return this.accountTable.update(data);
	}

	patch(accountId, data) {
		return this.accountTable.patch({ id: accountId }, data);
	}

	create(data) {
		return this.accountTable.create({ id: uuid.v4(), ...data });
	}

	remove(accountId) {
		return this.accountTable.remove({ id: accountId })
	}

	archive(accountId) {
		return this.accountTable.archive({ id: accountId });
	}

	retrieveByOwnerUserId(userId) {
		return this.accountTable.retrieveByOwnerUserId(userId);
	}

	retrieveByGroupId(groupId) {
		return this.accountTable.retrieveByGroupId(groupId);
	}
}

export default new DIFactory(AccountService, [AccountTable]);


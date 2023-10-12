import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import ClientTable from './ClientTable';
import ClientUserTable from './ClientUserTable';
import DIFactory from  '../../../util/DIFactory';
import uuid from 'uuid';

class ClientService {

	constructor(clientTable, clientUserTable) {
		this.clientTable = clientTable;
		this.clientUserTable = clientUserTable;
	}
	
  retrieve(clientId) {
		return this.clientTable.retrieve(clientId).then(({ Item }) => Item);
	}

	update(data) {
		return this.clientTable.update(data);
	}

	patch(clientId, data) {
		return this.clientTable.patch({ client_id: clientId }, data);
	}

	create(data) {
		return this.clientTable.create({ client_id: uuid.v4(), ...data });
	}

	remove(clientId) {
		return this.clientTable.remove({ client_id: clientId })
	}

	archive(clientId) {
		return this.clientTable.archive({ client_id: clientId });
	}

	patchRedirectURIWhitelist(clientId, data) {
		return this.clientTable.patch({ client_id: clientId }, data);
	}

	registerClientUser(clientId, userId) {
		return this.clientUserTable.create({ client_id: clientId, user_id: userId });
	}

	unregisterClientUser(clientId, userId) {
		return this.clientUserTable.patch({ client_id: clientId, user_id: userId }, { is_disabled: 1 });
	}

	retrieveClientUser(clientId, userId, shouldIncludeDisabled) {
		return this.clientUserTable.retrieve({ client_id: clientId, user_id: userId })
			.then(({ Item }) => (Item && (shouldIncludeDisabled || !Item.is_disabled) ? Item : {}));
	}

	retrieveClientsByUserId(userId) {
		return this.clientUserTable.retrieveByUserId(userId)
			.then(({ Items }) => ({
				data: Items.filter(({ is_disabled }) => !is_disabled)
			}));
	}
}

export default new DIFactory(ClientService, [ClientTable, ClientUserTable]);


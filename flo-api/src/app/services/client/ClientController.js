import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';
import ClientService from './ClientService';

class ClientController extends CrudController {
	constructor(clientService) {
		super(clientService.clientTable);
		this.clientService = clientService;
	}

  patchRedirectURIWhitelist({ token_metadata: { client_id }, body: data }) {
    return this.clientService.patchRedirectURIWhitelist(client_id, data);
  }

  retrieveClientUser({ params: { user_id, client_id } }) {
    return this.clientService.retrieveClientUser(client_id, user_id);
  }

  retrieveClientsByUserId({ params: { user_id } }) {
    return this.clientService.retrieveClientsByUserId(user_id);
  }
}

export default new DIFactory(new ControllerWrapper(ClientController), [ClientService])
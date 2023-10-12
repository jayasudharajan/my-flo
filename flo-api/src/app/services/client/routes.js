import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import ClientController from './ClientController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';

import _ from 'lodash';

class ClientACLStrategy {
	constructor(aclMiddleware, controller) {
		getAllControllerMethods(controller)	
			.forEach(method => {
				this[method] = aclMiddleware.requiresPermissions([{
					resource: 'Client',
					permission: method
				}]);
			});

		
		this.patchRedirectURIWhitelist = aclMiddleware.requiresPermissions([{
			resource: 'Client',
			permission: 'patchRedirectURIWhitelist'
		}]);

		this.retrieveClientUser = aclMiddleware.requiresPermissions([{
			resource: 'Client',
			permission: 'retrieveClientUser'
		}]);

		this.retrieveClientsByUserId = aclMiddleware.requiresPermissions([{
			resource: 'Client',
			permission: 'retrieveClientsByUserId'
		}]);
	}
}

class ClientRouteMap extends CrudRouteMap {
	constructor(controller) {
		super({ hashKey: 'client_id' }, controller);

		this.patchRedirectURIWhitelist = {
			post: '/client/redirect_uri_whitelist'
		};

		this.retrieveClientUser = {
			get: '/client/:client_id/user/:user_id'
		};

		this.retrieveClientsByUserId = {
			get: '/user/:user_id'
		};
	} 
}

class ClientRouter extends Router {
	constructor(authMiddleware, aclMiddleware, controller) {
		const auth = new AuthStrategy(authMiddleware, controller);
		const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
		const acl = new ClientACLStrategy(aclMiddleware, controller);
		const routeMap = new ClientRouteMap(controller);

		super(auth, validator, acl, controller, routeMap);
	}
}

export default DIFactory(ClientRouter, [AuthMiddleware, ACLMiddleware, ClientController]);
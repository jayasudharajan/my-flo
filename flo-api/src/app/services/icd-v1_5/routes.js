import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import ICDController from './ICDController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';

class ICDAuthStrategy extends AuthStrategy {
	constructor(authMiddleware, controller) {
		super(authMiddleware, controller);
	}
}

class ICDACLStrategy {
	constructor(aclMiddleware, controller) {
		getAllControllerMethods(controller)	
			.forEach(method => {
				this[method] = aclMiddleware.requiresPermissions([{
					resource: 'ICD',
					permission: method
				}]);
			});
	}
}

class ICDRouteMap extends CrudRouteMap {
	constructor(controller) {
		super({ hashKey: 'id' }, controller);

		this.retrieveByLocationId = {
			get: '/location/:location_id'
		};

		this.retrieveByDeviceId = {
			get: '/device/:device_id'
		};
	}
}

class ICDRouter extends Router {
	constructor(authMiddleware, aclMiddleware, controller) {
		const auth = new ICDAuthStrategy(authMiddleware, controller);
		const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
		const acl = new ICDACLStrategy(aclMiddleware, controller);
		const routeMap = new ICDRouteMap(controller);

		super(auth, validator, acl, controller, routeMap);
	}
}

export default DIFactory(ICDRouter, [AuthMiddleware, ACLMiddleware, ICDController]);
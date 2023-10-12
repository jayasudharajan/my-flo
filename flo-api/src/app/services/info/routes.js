import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import InfoController from './InfoController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import InfoACLStrategy from './InfoACLStrategy';
import InfoRouteMap from './InfoRouteMap';

class InfoRouter extends Router {
	constructor(authMiddleware, aclMiddleware, controller) { 
		const auth = new AuthStrategy(authMiddleware, controller);
		const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
		const acl = new InfoACLStrategy(aclMiddleware);
		const routeMap = new InfoRouteMap();

		super(auth, validator, acl, controller, routeMap);
	}
}

export default DIFactory(InfoRouter, [AuthMiddleware, ACLMiddleware, InfoController]);
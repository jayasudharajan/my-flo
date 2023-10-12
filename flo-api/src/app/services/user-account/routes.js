import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import ValidationStrategy from '../utils/ValidationStrategy';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import UserAccountController from './UserAccountController';
import Router from '../utils/Router';
import UserAccountACLStrategy from './UserAccountACLStrategy';

class UserAccountRouteMap {
	constructor() {
		this.createNewUserAndAccount = [
			{ post: '/' }
		];

		this.removeUserAndAccount = [
			{ delete: '/user/:user_id/account/:account_id/location/:location_id' }
		];	
	}
}

class UserAccountRouter extends Router {
	constructor(authMiddleware, aclMiddleware, controller) {
		const auth = new AuthStrategy(authMiddleware, controller);
		const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
		const acl = new UserAccountACLStrategy(aclMiddleware);
		const routeMap = new UserAccountRouteMap();

		super(auth, validator, acl, controller, routeMap);
	}
}

export default new DIFactory(UserAccountRouter, [AuthMiddleware, ACLMiddleware, UserAccountController]);
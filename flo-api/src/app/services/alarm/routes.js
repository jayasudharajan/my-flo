import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import ValidationStrategy from '../utils/ValidationStrategy';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import AlarmController from './AlarmController';
import Router from '../utils/Router';
import AlarmACLStrategy from './AlarmACLStrategy';

class AlarmRouteMap {
	constructor() {
		this.retrieveByICDId = [
			{ get: '/icd/:icd_id' },
			{ post: '/icd/:icd_id' }
		];

		this.retrieveDeliveryAnalytics = [
			{ get: '/analytics/delivery' },
			{ post: '/analytics/delivery' }
		];

		this.retrieveByIncidentId = {
			get: '/:incident_id' 
		};		
	}
}

class AlarmRouter extends Router {
	constructor(authMiddleware, aclMiddleware, controller) {
		const auth = new AuthStrategy(authMiddleware, controller);
		const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
		const acl = new AlarmACLStrategy(aclMiddleware);
		const routeMap = new AlarmRouteMap();

		super(auth, validator, acl, controller, routeMap);
	}
}

export default new DIFactory(AlarmRouter, [AuthMiddleware, ACLMiddleware, AlarmController]);
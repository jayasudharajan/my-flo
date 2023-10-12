import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import MicroLeakTestTimeValidationStrategy from './MicroLeakTestTimeValidationStrategy';
import MicroLeakTestTimeController from './MicroLeakTestTimeController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import MicroLeakTestTimeACLStrategy from './MicroLeakTestTimeACLStrategy';
import MicroLeakTestTimeRouteMap from './MicroLeakTestTimeRouteMap';

class MicroLeakTestTimeRouter extends Router {
	constructor(authMiddleware, aclMiddleware, controller) {
		const auth = new AuthStrategy(authMiddleware, controller, { addUserId: true });
		const validator = new MicroLeakTestTimeValidationStrategy({ reqValidate }, requestTypes, controller);
		const acl = new MicroLeakTestTimeACLStrategy(aclMiddleware);
		const routeMap = new MicroLeakTestTimeRouteMap();

		super(auth, validator, acl, controller, routeMap);
	}
}

export default new DIFactory(MicroLeakTestTimeRouter, [AuthMiddleware, ACLMiddleware, MicroLeakTestTimeController]);
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import LeakDayController from './LeakDayController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import LeakDayACLStrategy from './LeakDayACLStrategy';
import LeakDayRouteMap from './LeakDayRouteMap';

class LeakDayRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new LeakDayACLStrategy(aclMiddleware);
    const routeMap = new LeakDayRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(
  LeakDayRouter,
  [AuthMiddleware, ACLMiddleware, LeakDayController]
);
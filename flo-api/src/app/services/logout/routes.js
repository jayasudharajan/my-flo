import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import LogoutController from './LogoutController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';

class LogoutACLStrategy {
  // No authorization required since a token can only be used to log itself out
  logout(req, res, next) { 
    next();
  }
}

class LogoutRouteMap {
  constructor() {
    this.logout = [{
      post: '/'
    }];
  }
}

class LogoutRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new LogoutACLStrategy();
    const routeMap = new LogoutRouteMap(controller);

    super(auth, validator, acl, controller, routeMap);
  }
}

export default DIFactory(LogoutRouter, [AuthMiddleware, ACLMiddleware, LogoutController]);
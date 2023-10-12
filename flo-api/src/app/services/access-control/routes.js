import AuthMiddleware from '../utils/AuthMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import AccessControlController from './AccessControlController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';


class AccessControlACLStrategy {
  constructor() {
    this.authorize = (req, res, next) => next();

    this.refreshUserRoles = (req, res, next) => next();
  }
}

class AccessControlRouteMap {
  constructor() {
    this.authorize = {
      post: '/authorize'
    };

    this.refreshUserRoles = {
      post: '/refresh'
    }
  }
}

class AuthorizationRouter extends Router {
  constructor(authMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new AccessControlACLStrategy();
    const routeMap = new AccessControlRouteMap(controller);

    super(auth, validator, acl, controller, routeMap);
  }
}

export default DIFactory(AuthorizationRouter, [AuthMiddleware, AccessControlController]);
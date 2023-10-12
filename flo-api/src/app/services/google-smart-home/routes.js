import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import DIFactory from '../../../util/DIFactory';
import Router from '../utils/Router';
import GoogleSmartHomeACLStrategy from './GoogleSmartHomeACLStrategy';
import GoogleSmartHomeController from './GoogleSmartHomeController'
import GoogleSmartHomeRouteMap from "./GoogleSmartHomeRouteMap";
import ValidationStrategy from '../utils/ValidationStrategy';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';

import AuthStrategy from '../utils/AuthStrategy';


class GoogleSmartHomeRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const routeMap = new GoogleSmartHomeRouteMap();
    const acl = new GoogleSmartHomeACLStrategy(aclMiddleware);
    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(
  GoogleSmartHomeRouter,
  [AuthMiddleware, ACLMiddleware, GoogleSmartHomeController]
);

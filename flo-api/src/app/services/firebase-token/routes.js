import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import FirebaseTokenController from './FirebaseTokenController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import FirebaseTokenACLStrategy from './FirebaseTokenACLStrategy';
import FirebaseTokenRouteMap from './FirebaseTokenRouteMap';
import ICDService from '../icd-v1_5/ICDService';

class FirebaseTokenRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new FirebaseTokenACLStrategy(aclMiddleware, icdService);
    const routeMap = new FirebaseTokenRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(
  FirebaseTokenRouter,
  [AuthMiddleware, ACLMiddleware, FirebaseTokenController, ICDService]
);
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import FloDetectController from './FloDetectController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import FloDetectACLStrategy from './FloDetectACLStrategy';
import FloDetectRouteMap from './FloDetectRouteMap';
import ICDService from '../icd-v1_5/ICDService';

class FloDetectRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new FloDetectACLStrategy(aclMiddleware, icdService);
    const routeMap = new FloDetectRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(
  FloDetectRouter,
  [AuthMiddleware, ACLMiddleware, FloDetectController, ICDService]
);
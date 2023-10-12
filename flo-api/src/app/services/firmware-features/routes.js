import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import ValidationStrategy from '../utils/ValidationStrategy';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import FirmwareFeaturesController from './FirmwareFeaturesController';
import Router from '../utils/Router';

class FirmwareFeaturesRouteMap {
  constructor() {
    this.retrieveVersionFeatures = [
      { get: '/:version' }
    ];
  }
}

export default class FirmwareFeaturesACLStrategy {
  constructor(aclMiddleware) {
    this.retrieveVersionFeatures = aclMiddleware.requiresPermissions([{
      resource: 'ICD',
      permission: 'retrieveVersionFeatures'
    }]);
  }
}

class FirmwareFeaturesRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new FirmwareFeaturesACLStrategy(aclMiddleware);
    const routeMap = new FirmwareFeaturesRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(FirmwareFeaturesRouter, [AuthMiddleware, ACLMiddleware, FirmwareFeaturesController]);
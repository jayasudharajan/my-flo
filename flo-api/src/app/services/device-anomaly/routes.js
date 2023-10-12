import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import ValidationStrategy from '../utils/ValidationStrategy';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import DeviceAnomalyController from './DeviceAnomalyController';
import Router from '../utils/Router';

class DeviceAnomalyRouteMap {
  constructor() {
    this.handleDeviceAnomalyEvent = [
      {post: '/:type'}
    ];
    this.retrieveByAnomalyTypeAndDateRange = [
      {get: '/:type'}
    ];
  }
}

export default class DeviceAnomalyACLStrategy {
  constructor(aclMiddleware) {

    this.handleDeviceAnomalyEvent = aclMiddleware.requiresPermissions([{
      resource: 'ICD',
      permission: 'handleDeviceAnomalyEvent'
    }]);

    this.retrieveByAnomalyTypeAndDateRange = aclMiddleware.requiresPermissions([{
      resource: 'ICD',
      permission: 'retrieveByAnomalyTypeAndDateRange'
    }]);
  }
}

class DeviceAnomalyRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new DeviceAnomalyACLStrategy(aclMiddleware);
    const routeMap = new DeviceAnomalyRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(DeviceAnomalyRouter, [AuthMiddleware, ACLMiddleware, DeviceAnomalyController]);
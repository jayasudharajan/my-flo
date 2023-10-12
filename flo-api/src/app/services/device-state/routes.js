import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import ValidationStrategy from '../utils/ValidationStrategy';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import DeviceStateController from './DeviceStateController';
import Router from '../utils/Router';

class DeviceStateRouteMap {
  constructor() {
    this.forward = [
      { post: '/forward' }
    ];

    this.pairingSync = [
      { post: '/sync/pairing' }
    ];
  }
}

export default class DeviceStateACLStrategy {
  constructor(aclMiddleware) {
    this.forward = aclMiddleware.requiresPermissions([{
      resource: 'ICD',
      permission: 'forwardDeviceState'
    }]);

    this.pairingSync = aclMiddleware.requiresPermissions([{
      resource: 'ICD',
      permission: 'forwardDeviceState'
    }]);
  }
}

class DeviceStateRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new DeviceStateACLStrategy(aclMiddleware);
    const routeMap = new DeviceStateRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(DeviceStateRouter, [AuthMiddleware, ACLMiddleware, DeviceStateController]);
import Router from '../utils/Router';
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import ValidationStrategy from '../utils/ValidationStrategy';
import DIFactory from '../../../util/DIFactory';
import AwayModeController from './AwayModeController';
import ICDService from '../icd-v1_5/ICDService';
import ICDLocationProvider from '../utils/ICDLocationProvider';
import addAppUsedMiddleware from '../../middleware/addAppUsed';
import reqValidate from '../../middleware/reqValidate';
import requestTypes from './models/requestTypes';

class AwayModeACLStrategy {
  constructor(aclMiddleware, icdService) {

    this.icdLocationProvider = new ICDLocationProvider(icdService);

    this.retrieveIrrigationSchedule = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveIrrigationSchedule',
        get: (...args) => this.icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);

    this.enableDeviceAwayMode = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'toggleDeviceAwayMode',
        get: (...args) => this.icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);

    this.disableDeviceAwayMode = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'toggleDeviceAwayMode',
        get: (...args) => this.icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);

    this.retrieveAwayModeState = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveAwayModeState',
        get: (...args) => this.icdLocationProvider.getLocationIdByICDId(...args)
      }
    ]);
  }
}

class AwayModeRouteMap {
  constructor() {
    this.retrieveIrrigationSchedule = [
      {
        get: '/icd/:icd_id/irrigation'
      }
    ];

    this.enableDeviceAwayMode = [
      {
        post: '/icd/:icd_id/enable'
      }
    ];

    this.disableDeviceAwayMode = [
      {
        post: '/icd/:icd_id/disable'
      }
    ];

    this.retrieveAwayModeState = [
      {
        get: '/icd/:icd_id'
      }
    ];
  }
}

class AwayModeRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new AwayModeACLStrategy(aclMiddleware, icdService);
    const routeMap = new AwayModeRouteMap();

    super(auth, validator, acl, controller, routeMap, [addAppUsedMiddleware]);
  }
}

export default new DIFactory(AwayModeRouter, [AuthMiddleware, ACLMiddleware, AwayModeController, ICDService]);
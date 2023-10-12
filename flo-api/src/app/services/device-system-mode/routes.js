import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import DeviceSystemModeController from './DeviceSystemModeController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import DeviceSystemModeACLStrategy from './DeviceSystemModeACLStrategy';
import DeviceSystemModeRouteMap from './DeviceSystemModeRouteMap';
import ICDService from '../icd-v1_5/ICDService';
import addAppUsedMiddleware from '../../middleware/addAppUsed';
import ICDLocationProvider from '../utils/ICDLocationProvider';

class DeviceSystemModeRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new DeviceSystemModeACLStrategy(aclMiddleware, new ICDLocationProvider(icdService));
    const routeMap = new DeviceSystemModeRouteMap();

    super(auth, validator, acl, controller, routeMap, [addAppUsedMiddleware]);
  }
}

export default new DIFactory(
  DeviceSystemModeRouter,
  [AuthMiddleware, ACLMiddleware, DeviceSystemModeController, ICDService]
);
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import DeviceVPNController from './DeviceVPNController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import DeviceVPNACLStrategy from './DeviceVPNACLStrategy';
import DeviceVPNRouteMap from './DeviceVPNRouteMap';
import ICDService from '../icd-v1_5/ICDService';

class DeviceVPNRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller, { addUserId: true });
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new DeviceVPNACLStrategy(aclMiddleware, icdService);
    const routeMap = new DeviceVPNRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(
  DeviceVPNRouter,
  [AuthMiddleware, ACLMiddleware, DeviceVPNController, ICDService]
);
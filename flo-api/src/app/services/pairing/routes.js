import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import PairingController from './PairingController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import PairingACLStrategy from './PairingACLStrategy';
import PairingRouteMap from './PairingRouteMap';
import ICDService from '../icd-v1_5/ICDService';
import ICDLocationProvider from '../utils/ICDLocationProvider';
import addAppUsed from '../../middleware/addAppUsed';

class PairingRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new PairingACLStrategy(aclMiddleware, new ICDLocationProvider(icdService));
    const routeMap = new PairingRouteMap();

    super(auth, validator, acl, controller, routeMap, [addAppUsed]);
  }
}

export default new DIFactory(
  PairingRouter,
  [AuthMiddleware, ACLMiddleware, PairingController, ICDService]
);
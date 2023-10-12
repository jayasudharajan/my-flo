import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import FixtureDetectionController from './FixtureDetectionController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import FixtureDetectionACLStrategy from './FixtureDetectionACLStrategy';
import FixtureDetectionRouteMap from './FixtureDetectionRouteMap';
import ICDService from '../icd-v1_5/ICDService';

class FixtureDetectionRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new FixtureDetectionACLStrategy(aclMiddleware, icdService);
    const routeMap = new FixtureDetectionRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(
  FixtureDetectionRouter,
  [AuthMiddleware, ACLMiddleware, FixtureDetectionController, ICDService]
);
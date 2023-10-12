import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import ValidationStrategy from '../utils/ValidationStrategy';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import InsuranceLetterController from './InsuranceLetterController';
import Router from '../utils/Router';

class InsuranceLetterRouteMap {
  constructor() {
    this.generate = [
      { post: '/generate' }
    ];

    this.getDownloadInfo = [
      { get: '/download/info/:location_id' }
    ];

    this.redeem = [
      { post: '/download/redeem' }
    ];

    this.regenerate = [
      { post: '/regenerate' }
    ];
  }
}

export default class InsuranceLetterACLStrategy {
  constructor(aclMiddleware) {
    this.generate = aclMiddleware.requiresPermissions([{
      resource: 'Location',
      permission: 'generateInsuranceLetter',
      get: ({ body: { location_id } }) => Promise.resolve(location_id)
    }]);

    this.getDownloadInfo = aclMiddleware.requiresPermissions([{
      resource: 'Location',
      permission: 'downloadInsuranceLetter',
      get: ({ params: { location_id } }) => Promise.resolve(location_id)
    }]);

    this.redeem = aclMiddleware.requiresPermissions([{
      resource: 'Location',
      permission: 'downloadInsuranceLetter',
      get: ({ body: { location_id } }) => Promise.resolve(location_id)
    }]);

    this.regenerate = aclMiddleware.requiresPermissions([{
      resource: 'Location',
      permission: 'regenerateInsuranceLetter',
      get: ({ body: { location_id } }) => Promise.resolve(location_id)
    }]);
  }
}

class InsuranceLetterRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new InsuranceLetterACLStrategy(aclMiddleware);
    const routeMap = new InsuranceLetterRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(InsuranceLetterRouter, [AuthMiddleware, ACLMiddleware, InsuranceLetterController]);
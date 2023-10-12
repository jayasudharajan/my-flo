import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import AuthorizationController from './AuthorizationController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';

class AuthorizationAuthStrategy extends AuthStrategy {
  constructor(authMiddleware, controller) {
    super(authMiddleware, controller);
  }
}

class AuthorizationACLStrategy {
  constructor(aclMiddleware, controller) {
    this.retrieveUserAccountGroupRolesByGroupId = aclMiddleware.requiresPermissions([
      {
        resource: 'AccountGroup',
        permission: 'retrieveUserAccountGroupRolesByGroupId'
      }
    ]);

    this.retrieveUserAccountGroupRolesByUserId = aclMiddleware.requiresPermissions([
      {
        resource: 'AccountGroup',
        permission: 'retrieveUserAccountGroupRolesByUserId'
      },
      {
        resource: 'User',
        permission: 'retrieveUserAccountGroupRolesByUserId',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }
    ]);
  }
}

class AuthorizationRouteMap  {
  constructor(controller) {

    this.retrieveUserAccountGroupRolesByGroupId = {
      get: '/useraccountgrouproles/group/:group_id'
    };

    this.retrieveUserAccountGroupRolesByUserId = {
      get: '/useraccountgrouproles/user/:user_id'
    };
  }
}

class AuthorizationRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthorizationAuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new AuthorizationACLStrategy(aclMiddleware, controller);
    const routeMap = new AuthorizationRouteMap(controller);

    super(auth, validator, acl, controller, routeMap);
  }
}

export default DIFactory(AuthorizationRouter, [AuthMiddleware, ACLMiddleware, AuthorizationController]);
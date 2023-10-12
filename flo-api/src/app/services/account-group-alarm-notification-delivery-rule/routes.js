import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import AccountGroupAlarmNotificationDeliveryRuleController from './AccountGroupAlarmNotificationDeliveryRuleController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';

class AccountGroupAlarmNotificationDeliveryRuleAuthStrategy extends AuthStrategy {
  constructor(authMiddleware, controller) {
    super(authMiddleware, controller);
  }
}

class AccountGroupAlarmNotificationDeliveryRuleACLStrategy {
  constructor(aclMiddleware, controller) {
    getAllControllerMethods(controller) 
      .forEach(method => {
        const [ verb, dimension ] = method.split('By');
        const byDimension = dimension ? `By${ dimension }` : '';
        
        this[method] = aclMiddleware.requiresPermissions([{
          resource: 'AccountGroup',
          // Example permissions: 
          // retrieveAccountGroupAlarmNotificationDeliveryRule
          // retrieveAccountGroupAlarmNotificationDeliveryRuleByGroupId
          permission: `${ verb }AccountGroupAlarmNotificationDeliveryRule${ byDimension }`,
          get: ({ params: { group_id } }) => Promise.resolve(group_id)
        }]);
      });
  }
}

class AccountGroupAlarmNotificationDeliveryRuleRouteMap extends CrudRouteMap {
  constructor(controller) {
    super({ hashKey: 'group_id', rangeKey: 'alarm_id_system_mode_user_role' }, controller);

    this.retrieveByGroupId = {
      get: '/:group_id'
    };

    this.retrieveByGroupIdAlarmIdSystemMode = {
      get:'/:group_id/:alarm_id/:system_mode'
    };
  }
}

class AccountGroupAlarmNotificationDeliveryRuleRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AccountGroupAlarmNotificationDeliveryRuleAuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new AccountGroupAlarmNotificationDeliveryRuleACLStrategy(aclMiddleware, controller);
    const routeMap = new AccountGroupAlarmNotificationDeliveryRuleRouteMap(controller);

    super(auth, validator, acl, controller, routeMap);
  }
}

export default DIFactory(AccountGroupAlarmNotificationDeliveryRuleRouter, [AuthMiddleware, ACLMiddleware, AccountGroupAlarmNotificationDeliveryRuleController]);
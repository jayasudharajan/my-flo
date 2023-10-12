import _ from 'lodash';
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import PushNotificationTokenController from './PushNotificationTokenController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';

class PushNotificationTokenACLStrategy {
  constructor(aclMiddleware, controller) {
    getAllControllerMethods(controller)
      .forEach(method => {
        
        this[method] = aclMiddleware.requiresPermissions([{
          resource: 'PushNotificationToken',
          permission: method
        }]);
      });

      this.retrieveByUserId = aclMiddleware.requiresPermissions([
        {
          resource: 'PushNotificationToken',
          permission: 'retrieveByUserId'
        }
      ]);

      this.registerIOSToken = aclMiddleware.requiresPermissions([{
        resource: 'PushNotificationToken',
        permission: 'registerPushNotificationToken'
      }]);

      this.registerAndroidToken = aclMiddleware.requiresPermissions([{
        resource: 'PushNotificationToken',
        permission: 'registerPushNotificationToken'
      }]);
  }
}

class PushNotificationTokenRouteMap extends CrudRouteMap{
  constructor(controller) {
    super(
      { 
        hashKey: 'mobile_device_id', 
        rangeKey: 'client_id' 
      }, 
      controller, 
      {
        retrieveByUserId: {
          get: '/user/:user_id'
        }
      }
    );

    this.registerIOSToken = {
      post: '/ios'
    };

    this.registerAndroidToken = {
      post: '/android'
    };
  }
}

class PushNotificationTokenRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new PushNotificationTokenACLStrategy(aclMiddleware, controller);
    const routeMap = new PushNotificationTokenRouteMap(controller);

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(PushNotificationTokenRouter, [AuthMiddleware, ACLMiddleware, PushNotificationTokenController]);
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import SubscriptionController from './SubscriptionController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';

class SubscriptionAuthStrategy extends AuthStrategy {
  constructor(authMiddleware, stripeWebhookAuthMiddleware, controller) {
    super(authMiddleware, controller);

    this.handleStripeWebhookEvent = stripeWebhookAuthMiddleware.requiresAuth();
  }
}

class SubscriptionACLStrategy {
  constructor(aclMiddleware, controller) {
    getAllControllerMethods(controller)
      .filter(method => method != 'handleStripeWebhookEvent' && method != 'handleStripePayment')
      .forEach(method => {
        
        this[method] = aclMiddleware.requiresPermissions([{
          resource: 'AccountSubscription',
          permission: method
        }]);
      });

      this.retrieveByUserId = aclMiddleware.requiresPermissions([
        {
          resource: 'User',
          permission: 'retrieveAccountSubscription',
          get: ({ params: { user_id } }) => Promise.resolve(user_id)
        },
        {
          resource: 'AccountSubscription',
          permission: 'retrieveByUserId'
        }
      ]);

      this.handleStripePayment = aclMiddleware.requiresPermissions([{
        resource: 'User',
        permission: 'handleStripePayment',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }]);

      this.retrievePaymentSource = aclMiddleware.requiresPermissions([{
        resource: 'User',
        permission: 'handleStripePayment',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }]);

      this.updatePaymentSource = aclMiddleware.requiresPermissions([{
        resource: 'User',
        permission: 'handleStripePayment',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }]);

      this.cancelSubscriptionByUserId = aclMiddleware.requiresPermissions([{
        resource: 'User',
        permission: 'cancelAccountSubscription',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }]);

      this.cancelSubscriptionByUserIdWithReason = aclMiddleware.requiresPermissions([{
        resource: 'User',
        permission: 'cancelAccountSubscription',
        get: ({ params: { user_id } }) => Promise.resolve(user_id)
      }]);
  }

  handleStripeWebhookEvent(req, res, next) {
    next();
  }
}

class SubscriptionRouteMap extends CrudRouteMap {
  constructor(controller) {
    super({ hashKey: 'account_id' }, controller);

    this.retrieveByUserId = {
      get: '/user/:user_id'
    };

    this.handleStripeWebhookEvent = {
      post: '/webhook/stripe'
    };

    this.retrieveSubscriptionPlan = {
      get: '/plan/:plan_id'
    };

    this.handleStripePayment = {
      post: '/user/:user_id/payment/stripe'
    };

    this.retrievePaymentSource = {
      get: '/user/:user_id/payment'
    };

    this.updatePaymentSource = {
      post: '/user/:user_id/payment'
    };

    this.retrieveCouponInfo = {
      get: '/coupon/:coupon_id'
    };

    this.cancelSubscriptionByUserId = {
      delete: '/user/:user_id'
    };

    this.cancelSubscriptionByUserIdWithReason = {
      post: '/user/:user_id/cancel'
    };
  }
}

class SubscriptionRouter extends Router {
  constructor(authMiddleware, stripeWebhookAuthMiddleware, aclMiddleware, controller) {
    const auth = new SubscriptionAuthStrategy(authMiddleware, stripeWebhookAuthMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new SubscriptionACLStrategy(aclMiddleware, controller);
    const routeMap = new SubscriptionRouteMap(controller);

    super(auth, validator, acl, controller, routeMap);
  }
}

export default new DIFactory(SubscriptionRouter, [AuthMiddleware, ['StripeWebhook', AuthMiddleware], ACLMiddleware, SubscriptionController]);
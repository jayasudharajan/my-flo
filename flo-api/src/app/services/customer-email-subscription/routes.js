import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import CustomerEmailSubscriptionController from './CustomerEmailSubscriptionController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import CustomerEmailSubscriptionAuthStrategy from './CustomerEmailSubscriptionAuthStrategy';
import CustomerEmailSubscriptionACLStrategy from './CustomerEmailSubscriptionACLStrategy';
import CustomerEmailSubscriptionRouteMap from './CustomerEmailSubscriptionRouteMap';

class CustomerEmailSubscriptionRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new CustomerEmailSubscriptionAuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new CustomerEmailSubscriptionACLStrategy(aclMiddleware);
    const routeMap = new CustomerEmailSubscriptionRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }
}

export default DIFactory(CustomerEmailSubscriptionRouter, [AuthMiddleware, ACLMiddleware, CustomerEmailSubscriptionController]);
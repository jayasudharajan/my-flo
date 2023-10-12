import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthStrategy from '../utils/AuthStrategy';
import CrudRouteMap from '../utils/CrudRouteMap';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import { getAllControllerMethods } from '../utils/utils';
import AlertFeedbackController from './AlertFeedbackController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import ICDService from '../icd-v1_5/ICDService';
import ICDLocationProvider from '../utils/ICDLocationProvider';

import _ from 'lodash';

class AlertFeedbackACLStrategy {
  constructor(aclMiddleware, icdLocationProvider) {
    this.submitFeedback = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'submitAlertFeedback',
        get: ({ body: { icd_id } }) => icdLocationProvider.getLocationIdByICDId({ params: { icd_id } })
      }
    ]);

    this.retrieveFeedback = aclMiddleware.requiresPermissions([
      {
        resource: 'Location',
        permission: 'retrieveAlertFeedback',
        get: req => icdLocationProvider.getLocationIdByICDId(req)
      }
    ]);

    this.retrieveFlow = aclMiddleware.requiresPermissions([
      { 
        resource: 'ICDAlarmNotificationDeliveryRule',
        permission: 'retrieve'
      }
    ]);
  }
}

class AlertFeedbackRouteMap {
  constructor() {

    this.submitFeedback = {
      post: '/'
    };

    this.retrieveFeedback = {
      get: '/:icd_id/:incident_id'
    };

    this.retrieveFlow = {
      get: '/flow/:alarm_id/:system_mode'
    };
  } 
}

class AlertFeedbackRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller, icdService) {
    const auth = new AuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({ reqValidate }, requestTypes, controller);
    const acl = new AlertFeedbackACLStrategy(aclMiddleware, new ICDLocationProvider(icdService));
    const routeMap = new AlertFeedbackRouteMap(controller);

    super(auth, validator, acl, controller, routeMap);
  }
}

export default DIFactory(AlertFeedbackRouter, [AuthMiddleware, ACLMiddleware, AlertFeedbackController, ICDService]);
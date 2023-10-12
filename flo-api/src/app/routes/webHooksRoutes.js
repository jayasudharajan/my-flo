var  express = require( 'express');
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

var webHooksController = require('../controllers/webHooksController');
let ICDAlarmIncidentRegistryLogController = require('../controllers/ICDAlarmIncidentRegistryLogController');
var emailDeliveryLogController = require('../controllers/emailDeliveryLogController');
var SMSDeliveryLogController = require('../controllers/SMSDeliveryLogController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('WebHooks');


  // ### Internal Web hooks for Flo Apps

  // This is for Email-Service
  router.route('/email/:icd_alarm_incident_registry_id/:user_id')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('emailServiceWebhook'),
      webHooksController.emailServiceWebhook);

  // This is for SMS-Service
  router.route('/sms/efafacc1b3e977580ebf/:icd_alarm_incident_registry_id/:user_id')
    .post(
      authMiddleware.requiresAuth(),
      ICDAlarmIncidentRegistryLogController.create);


  // ### External callback Endpoints for Third-Party services

  // Email hook for SendWithUs -> SendGrid -> Flo API. SendGrid Docs: https://sendgrid.com/docs/API_Reference/Webhooks/event.html
  // TODO: Think about authentication. SendGrid supports HTTP Basic Authorization
  router.route('/email/sendgrid/969dcd48f3de09fc67d0/status')
    .post(
      authMiddleware.requiresAuth(),
      webHooksController.logEmailStatus);

  // SMS hook for Twilio -> Flo API. Twilio Docs: https://www.twilio.com/docs/api/rest/sending-messages
  router.route('/sms/twilio/4e3193eaa0670968e9e6/status')
    .post(
      authMiddleware.requiresAuth(),
      webHooksController.logSmsStatus);

  // router.route('/createemaillog/3fe93a1d-020c-4575-828c-03466d6cc389')
  //   .post(emailDeliveryLogController.create);

  // router.route('/createsmslog/c82fbf66-1c40-49ef-83f7-2ed7f4069c34')
  //   .post(SMSDeliveryLogController.create);



  app.use('/api/v1/hooks', router);
}

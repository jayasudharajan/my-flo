import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';


let ICDAlarmNotificationDeliveryRuleController = require('../controllers/ICDAlarmNotificationDeliveryRuleController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ICDAlarmNotificationDeliveryRule');

  // // Archive.
  // router.route('/archive/:alarm_id/:system_mode')
  //   .delete(
  //     requiresAuth(),
  //     requiresPermission('archive'),
  //     ICDAlarmNotificationDeliveryRuleController.archive);

  // Query by alarm_id.
  router.route('/alarmid/:alarm_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationDeliveryRuleValidators.retrieveByAlarmId,
      requiresPermission('retrieveByAlarmId'),
      ICDAlarmNotificationDeliveryRuleController.retrieveByAlarmId
    );

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      ICDAlarmNotificationDeliveryRuleController.scan);

  // Get, update, patch, delete.
  router.route('/:alarm_id/:system_mode')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationDeliveryRuleValidators.retrieve,
      requiresPermission('retrieve'),
      ICDAlarmNotificationDeliveryRuleController.retrieve
    )
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationDeliveryRuleValidators.update,
      requiresPermission('update'),
      ICDAlarmNotificationDeliveryRuleController.update
    )
    .put(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationDeliveryRuleValidators.patch,
      requiresPermission('patch'),
      ICDAlarmNotificationDeliveryRuleController.patch
    )
    .delete(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationDeliveryRuleValidators.remove,
      requiresPermission('remove'),
      ICDAlarmNotificationDeliveryRuleController.remove
    );

  // Create
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationDeliveryRuleValidators.create,
      requiresPermission('create'),
      ICDAlarmNotificationDeliveryRuleController.create
    );

  app.use('/api/v1/icdalarmnotificationdeliveryrules', router);

}

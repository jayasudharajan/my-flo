import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByICDId } from '../../util/icdUtils';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let AlarmNotificationDeliveryFilterController = require('../controllers/alarmNotificationDeliveryFilterController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('AlarmNotificationDeliveryFilter');
  let getLocationId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => location_id);

  // Get most severe alarm.
  router.route('/severe/:icd_id')
    .get(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.retrieveHighestSeverityByICDId,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'retrieveAlarmNotificationDeliveryFilterHighestSeverityByICDId',
          get: getLocationId
        },
        {
          resource: 'AlarmNotificationDeliveryFilter',
          permission: 'retrieveHighestSeverityByICDId'
        }
      ]),
      AlarmNotificationDeliveryFilterController.retrieveHighestSeverityByICDId
    );

  // Archive.
  router.route('/archive/:icd_id/:alarm_id/:system_mode')
    .delete(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.archive,
      requiresPermission('archive'),
      AlarmNotificationDeliveryFilterController.archive);

  // Get, update, patch, delete.
  router.route('/:icd_id/:alarm_id/:system_mode')
    .get(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.retrieve,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'retrieveAlarmNotificationDeliveryFilter',
          get: getLocationId
        },
        {
          resource: 'AlarmNotificationDeliveryFilter',
          permission: 'retrieve'
        }
      ]),
      AlarmNotificationDeliveryFilterController.retrieve
    )
    .post(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.update,
      requiresPermission('update'),
      AlarmNotificationDeliveryFilterController.update
    )
    .put(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.patch,
      requiresPermission('patch'),
      AlarmNotificationDeliveryFilterController.patch
    )
    .delete(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.remove,
      requiresPermission('remove'),
      AlarmNotificationDeliveryFilterController.remove
    );

  // Query by icd_id and alarm_id.
  router.route('/:icd_id/:alarm_id')
    .get(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.retrieveByICDIdAlarmId,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'retrieveAlarmNotificationDeliveryFilterByICDIdAlarmId',
          get: getLocationId
        },
        {
          resource: 'AlarmNotificationDeliveryFilter',
          permission: 'retrieveByICDIdAlarmId'
        }
      ]),
      AlarmNotificationDeliveryFilterController.retrieveByICDIdAlarmId
    );

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      AlarmNotificationDeliveryFilterController.scan);  // For testing only!!!

  // Query by icd_id.
  router.route('/:icd_id')
    .get(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.retrieveByICDId,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'retrieveAlarmNotificationDeliveryFilterByICDId',
          get: getLocationId
        },
        {
          resource: 'AlarmNotificationDeliveryFilter',
          permission: 'retrieveByICDId'
        }
      ]),
      AlarmNotificationDeliveryFilterController.retrieveByICDId
    );

  // Create
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //alarmNotificationDeliveryFilterValidators.create,
      requiresPermission('create'),
      AlarmNotificationDeliveryFilterController.create
    );

  app.use('/api/v1/alarmnotificationdeliveryfilters', router);

}

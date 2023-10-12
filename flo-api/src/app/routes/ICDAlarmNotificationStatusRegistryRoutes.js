import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByDeviceId } from '../../util/icdUtils';
import { lookupByLocationId } from '../../util/accountGroupUtils';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let ICDAlarmNotificationStatusRegistryController = require('../controllers/ICDAlarmNotificationStatusRegistryController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ICDAlarmNotificationStatusRegistry');
  let getGroupIdByIcdId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));


  // Query by GSI.
  router.route('/icd/:icd_id/:incident_time')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.retrieveByIcdIdAndIncidentTime,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveICDAlarmNotificationStatusRegistryByIcdIdAndIncidentTime',
          get: getGroupIdByIcdId
        },
        {
          resource: 'ICDAlarmNotificationStatusRegistry',
          permission: 'retrieveByIcdIdAndIncidentTime'
        }
      ]),
      ICDAlarmNotificationStatusRegistryController.retrieveByIcdIdAndIncidentTime
    );

  router.route('/icdalarmincidentregistry/:icd_alarm_incident_registry_id/:incident_time')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.retrieveByIcdAlarmIncidentRegistryIdAndIncidentTime,
      requiresPermission('retrieveByIcdAlarmIncidentRegistryIdAndIncidentTime'),
      ICDAlarmNotificationStatusRegistryController.retrieveByIcdAlarmIncidentRegistryIdAndIncidentTime
    );

  // Archive.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.archive,
      requiresPermission('archive'),
      ICDAlarmNotificationStatusRegistryController.archive);

  // Query by GSI hashkey.
  router.route('/icd/:icd_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.retrieveByIcdId,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveICDAlarmNotificationStatusRegistryByIcdId',
          get: getGroupIdByIcdId
        },
        {
          resource: 'ICDAlarmNotificationStatusRegistry',
          permission: 'retrieveByIcdId'
        }
      ]),
      ICDAlarmNotificationStatusRegistryController.retrieveByIcdId
    );

  router.route('/icdalarmincidentregistry/:icd_alarm_incident_registry_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.retrieveByIcdAlarmIncidentRegistryId,
      requiresPermission('retrieveByIcdAlarmIncidentRegistryId'),
      ICDAlarmNotificationStatusRegistryController.retrieveByIcdAlarmIncidentRegistryId
    );

  // router.route('/scan')
  //   .get(
  //     requiresAuth(),
  //     requiresPermission('scan'),
  //     ICDAlarmNotificationStatusRegistryController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.retrieve,
      requiresPermission('retrieve'),
      ICDAlarmNotificationStatusRegistryController.retrieve
    )
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.update,
      requiresPermission('update'),
      ICDAlarmNotificationStatusRegistryController.update
    )
    .put(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.patch,
      requiresPermission('patch'),
      ICDAlarmNotificationStatusRegistryController.patch
    )
    .delete(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.remove,
      requiresPermission('remove'),
      ICDAlarmNotificationStatusRegistryController.remove
    );

  // Create
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmNotificationStatusRegistryValidator.create,
      requiresPermission('create'),
      ICDAlarmNotificationStatusRegistryController.create
    );

  app.use('/api/v1/icdalarmnotificationstatusregistry', router);

}
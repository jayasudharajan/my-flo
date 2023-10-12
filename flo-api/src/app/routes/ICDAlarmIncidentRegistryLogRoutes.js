import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let ICDAlarmIncidentRegistryLogController = require('../controllers/ICDAlarmIncidentRegistryLogController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ICDAlarmIncidentRegistryLog');

  // Query by receipt_id.
  router.route('/receipt/:receipt_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryLogValidators.retrieveByReceiptId,
      requiresPermission('retrieveByReceiptId'),
      ICDAlarmIncidentRegistryLogController.retrieveByReceiptId
    )

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      ICDAlarmIncidentRegistryLogController.scan
    );  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:icd_alarm_incident_registry_id/:delivery_medium/:status')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryLogValidators.retrieve,
      requiresPermission('retrieve'),
      ICDAlarmIncidentRegistryLogController.retrieve
    );    
    // .post(ICDAlarmIncidentRegistryLogController.update)
    // .put(ICDAlarmIncidentRegistryLogController.patch)
    // .delete(ICDAlarmIncidentRegistryLogController.remove);

  // Query by icd_alarm_incident_registry_id.
  router.route('/:icd_alarm_incident_registry_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryLogValidators.retrieveByIncidentId,
      requiresPermission('retrieveByIncidentId'),
      ICDAlarmIncidentRegistryLogController.retrieveByIncidentId
    );

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryLogValidators.create,
      requiresPermission('create'),
      ICDAlarmIncidentRegistryLogController.create
    );

  app.use('/api/v1/icdalarmincidentregistrylogs', router);

}
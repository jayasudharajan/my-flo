import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByICDId } from '../../util/icdUtils';
import { lookupByLocationId } from '../../util/accountGroupUtils';
import AuthMiddleware from '../services/utils/AuthMiddleware';
let ICDAlarmIncidentRegistryController = require('../controllers/ICDAlarmIncidentRegistryController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ICDAlarmIncidentRegistry');
  let getGroupIdByICDId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));

  // Get all incidents by ICD to 'acknowleged'.
  router.route('/icd/severe/:icd_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveHighestSeverityByICDId,
      requiresPermission('retrieveHighestSeverityByICDId'),
      ICDAlarmIncidentRegistryController.retrieveHighestSeverityByICDId);

  // Get all incidents by ICD to 'acknowleged'.
  router.route('/icd/clear/:icd_id')
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.setAcknowledgedByICDId,
      requiresPermission('setAcknowledgedByICDId'),
      ICDAlarmIncidentRegistryController.setAcknowledgedByICDId);

  // Get all incidents by ICD unacknowleged by user.
  router.route('/icd/all/:icd_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveByICDId,
      requiresPermission('retrieveByICDId'),
      ICDAlarmIncidentRegistryController.retrieveByICDId);

  router.route('/icd/all/:icd_id/:limit')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveByICDId,
      requiresPermission('retrieveByICDId'),
      ICDAlarmIncidentRegistryController.retrieveByICDId);

  router.route('/icd/all/:icd_id/:limit/:id/:acknowledged_by_user')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveByICDId,
      requiresPermission('retrieveByICDId'),
      ICDAlarmIncidentRegistryController.retrieveByICDId);

  // Get all incidents by ICD sort by time.
  router.route('/icd/recent/:icd_id/:limit')
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveNewestByICDId,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveNewestByICDId',
          get: getGroupIdByICDId
        }
      ]),
      ICDAlarmIncidentRegistryController.retrieveNewestByICDId);

  router.route('/icd/list/:icd_id/:count')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveByICDIdIncidentTime,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveICDAlarmIncidentRegistryByICDIdIncidentTime',
          get: getGroupIdByICDId
        },
        {
          resource: 'ICDAlarmIncidentRegistry',
          permission: 'retrieveByICDIdIncidentTime'
        }
      ]),
      ICDAlarmIncidentRegistryController.retrieveByICDIdIncidentTime);

  router.route('/icd/list/:icd_id/:count/:id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveByICDIdIncidentTime,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveICDAlarmIncidentRegistryByICDIdIncidentTime',
          get: getGroupIdByICDId
        },
        {
          resource: 'ICDAlarmIncidentRegistry',
          permission: 'retrieveByICDIdIncidentTime'
        }
      ]),
      ICDAlarmIncidentRegistryController.retrieveByICDIdIncidentTime);

  router.route('/icd/recent/:icd_id')
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveNewestByICDId,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveNewestByICDId',
          get: getGroupIdByICDId
        }
      ]),
      ICDAlarmIncidentRegistryController.retrieveNewestByICDId); 

  // Get all incidents by ICD unacknowleged by user.
  router.route('/icd/unacknowleged/:icd_id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.retrieveUnacknowledgedByICDId,
      requiresPermission('retrieveUnacknowledgedByICDId'),
      ICDAlarmIncidentRegistryController.retrieveUnacknowledgedByICDId);

  // Faux delete.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.archive,
      requiresPermission('archive'),
      ICDAlarmIncidentRegistryController.archive);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      ICDAlarmIncidentRegistryController.scan);  // For testing only!!!

  router.route('/scan/:limit')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.scan,
      requiresPermission('scan'),
      ICDAlarmIncidentRegistryController.scan);  // For testing only!!!

  router.route('/scan/:limit/:id')
    .get(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.scan,
      requiresPermission('scan'),
      ICDAlarmIncidentRegistryController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .all(authMiddleware.requiresAuth())
    .get(
      //ICDAlarmIncidentRegistryValidators.retrieve,
      requiresPermission('retrieve'),
      ICDAlarmIncidentRegistryController.retrieve)
    .post(
      //ICDAlarmIncidentRegistryValidators.update,
      requiresPermission('update'),
      ICDAlarmIncidentRegistryController.update)
    .put(
      //ICDAlarmIncidentRegistryValidators.patch,
      requiresPermission('patch'),
      ICDAlarmIncidentRegistryController.patch)
    .delete(
      //ICDAlarmIncidentRegistryValidators.remove,
      requiresPermission('delete'),
      ICDAlarmIncidentRegistryController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //ICDAlarmIncidentRegistryValidators.create,
      requiresPermission('create'),
      ICDAlarmIncidentRegistryController.create);

  app.use('/api/v1/icdalarmincidentregistries', router);

}
import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let appDeviceNotificationInfoController = require('../controllers/appDeviceNotificationInfoController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('AppDeviceNotificationInfo');

  // Faux delete.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //appDeviceNotificationInfoValidators.archive,
      requiresPermission('archive'),
      appDeviceNotificationInfoController.archive);

  router.route('/:user_id/:icd_id')
    .get(
      authMiddleware.requiresAuth(),
      //appDeviceNotificationInfoValidators.retrieveByUserIdICDId,
      requiresPermission('retrieveByUser'),
      appDeviceNotificationInfoController.retrieveByUserIdICDId);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      appDeviceNotificationInfoController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .all(authMiddleware.requiresAuth())
    .get(
      //appDeviceNotificationInfoValidators.retrieve,
      requiresPermission('retrieve'),
      appDeviceNotificationInfoController.retrieve)
    .post(
      //appDeviceNotificationInfoValidators.update,
      requiresPermission('update'),
      appDeviceNotificationInfoController.update)
    .put(
      //appDeviceNotificationInfoValidators.patch,
      requiresPermission('patch'),
      appDeviceNotificationInfoController.patch)
    .delete(
      //appDeviceNotificationInfoValidators.remove,
      requiresPermission('delete'),
      appDeviceNotificationInfoController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //appDeviceNotificationInfoValidators.create,
      requiresPermission('create'),
      appDeviceNotificationInfoController.create)

  app.use('/api/v1/appdevicenotificationinfo', router);

}
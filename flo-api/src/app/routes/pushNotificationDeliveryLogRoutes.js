import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let pushNotificationDeliveryLogController = require('../controllers/pushNotificationDeliveryLogController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('PushNotificationDeliveryLog');

  // Faux delete.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      requiresPermission('archive'),
      pushNotificationDeliveryLogController.archive);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      pushNotificationDeliveryLogController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .all(authMiddleware.requiresAuth())
    .get(
      requiresPermission('retrieve'),
      pushNotificationDeliveryLogController.retrieve)
    .post(
      requiresPermission('update'),
      pushNotificationDeliveryLogController.update)
    .put(
      requiresPermission('patch'),
      pushNotificationDeliveryLogController.patch)
    .delete(
      requiresPermission('delete'),
      pushNotificationDeliveryLogController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('create'),
      pushNotificationDeliveryLogController.create);

  // app.use('/api/v1/pushnotificationdeliverylogs', router);

}
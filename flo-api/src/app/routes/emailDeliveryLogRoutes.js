import express from 'express';
import AuthMiddleware from '../services/utils/AuthMiddleware';
import { checkPermissions } from '../middleware/acl';

let emailDeliveryLogController = require('../controllers/emailDeliveryLogController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('EmailDeliveryLog');

  // Faux delete.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //emailDeliveryLogValidators.archive,
      requiresPermission('archive'),
      emailDeliveryLogController.archive);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      emailDeliveryLogController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .all(authMiddleware.requiresAuth())
    .get(
      //emailDeliveryLogValidators.retrieve,
      requiresPermission('retrieve'),
      emailDeliveryLogController.retrieve)
    .post(
      //emailDeliveryLogValidators.update,
      requiresPermission('update'),
      emailDeliveryLogController.update)
    .put(
      //emailDeliveryLogValidators.patch,
      requiresPermission('patch'),
      emailDeliveryLogController.patch)
    .delete(
      //emailDeliveryLogValidators.remove,
      requiresPermission('remove'),
      emailDeliveryLogController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //emailDeliveryLogValidators.create,
      requiresPermission('create'),
      emailDeliveryLogController.create)

  app.use('/api/v1/emaildeliverylogs', router);

}
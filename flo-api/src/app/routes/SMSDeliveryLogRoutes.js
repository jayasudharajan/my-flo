import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let SMSDeliveryLogController = require('../controllers/SMSDeliveryLogController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('SMSDeliveryLog');

  // Faux delete.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //SMSDeliveryLogValidators.archive,
      requiresPermission('archive'),
      SMSDeliveryLogController.archive);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      SMSDeliveryLogController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .all(authMiddleware.requiresAuth())
    .get(
      //SMSDeliveryLogValidators.retrieve,
      requiresPermission('retrieve'),
      SMSDeliveryLogController.retrieve)
    .post(
      //SMSDeliveryLogValidators.update,
      requiresPermission('update'),
      SMSDeliveryLogController.update)
    .put(
      //SMSDeliveryLogValidators.patch,
      requiresPermission('patch'),
      SMSDeliveryLogController.patch)
    .delete(
      //SMSDeliveryLogValidators.remove,
      requiresPermission('delete'),
      SMSDeliveryLogController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //SMSDeliveryLogValidators.create,
      requiresPermission('create'),
      SMSDeliveryLogController.create)

  app.use('/api/v1/smsdeliverylogs', router);

}
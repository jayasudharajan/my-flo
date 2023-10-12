import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let kernelVersionController = require('../controllers/kernelVersionController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('KernelVersion');

  // Get, update, patch, delete.
  router.route('/:model/:version')
    .all(authMiddleware.requiresAuth())
    .get(
      //kernelVersionValidators.retrieve,
      requiresPermission('retrieve'),
      kernelVersionController.retrieve)
    .post(
      //kernelVersionValidators.update,
      requiresPermission('update'),
      kernelVersionController.update)
    .put(
      //kernelVersionValidators.patch,
      requiresPermission('patch'),
      kernelVersionController.patch)
    .delete(
      //kernelVersionValidators.remove,
      requiresPermission('delete'),
      kernelVersionController.remove);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      kernelVersionController.scan);  // For testing only!!!

  // Get by model.
  router.route('/:model')
    .get(
      authMiddleware.requiresAuth(),
      //kernelVersionValidators.retrieveByModel,
      requiresPermission('retrieveByModel'),
      kernelVersionController.queryPartition);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //kernelVersionValidators.create,
      requiresPermission('create'),
      kernelVersionController.create);

  app.use('/api/v1/kernelversions', router);

}
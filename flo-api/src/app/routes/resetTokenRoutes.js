import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let resetTokenController = require('../controllers/resetTokenController');

// NOTE: should resettoken even have routes?

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ResetToken');

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      resetTokenController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:user_id')
    .all(authMiddleware.requiresAuth())
    .get(
      //resetTokenValidators.retrieve,
      requiresPermission('retrieve'),
      resetTokenController.retrieve)
    .post(
      requiresPermission('update'),
      resetTokenController.update)
    .put(
      requiresPermission('patch'),
      resetTokenController.patch)
    .delete(
      //resetTokenValidators.remove,
      requiresPermission('delete'),
      resetTokenController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //resetTokenValidators.create,
      requiresPermission('create'),
      resetTokenController.create);

  app.use('/api/v1/resettokens', router);

}
import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let registrationTokenController = require('../controllers/registrationTokenController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('RegistrationToken');

  // Get, update, patch, delete.
  router.route('/:token1/:token2')
    .all(authMiddleware.requiresAuth())
    .get(
      //registrationTokenValidators.retrieve,
      requiresPermission('create'),
      registrationTokenController.retrieve)
    .post(
      //registrationTokenValidators.update,
      requiresPermission('update'),
      registrationTokenController.update)
    .put(
      //registrationTokenValidators.patch,
      requiresPermission('patch'),
      registrationTokenController.patch)
    .delete(
      //registrationTokenValidators.remove,
      requiresPermission('delete'),
      registrationTokenController.remove);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      registrationTokenController.scan);  // For testing only!!!

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //registrationTokenValidators.create,
      requiresPermission('create'),
      registrationTokenController.create);

  app.use('/api/v1/registrationtokens', router);

}
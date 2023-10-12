import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let userDetailController = require('../controllers/userDetailController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('UserDetail');

  // Faux delete.
  router.route('/archive/:user_id')
    .delete(
      authMiddleware.requiresAuth(),
      //userDetailValidators.archive,
      requiresPermission('archive'),
      userDetailController.archive);

  // Returns User + UserDetail.
  router.route('/user/:user_id')
    .get(
      authMiddleware.requiresAuth(),
      //userDetailValidators.retrieveWithUser,
      requiresPermission('retrieveWithUser'),
      userDetailController.retrieveWithUser);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(), 
      requiresPermission('scan'),
      userDetailController.scan);  // For testing only!!!

  // Get, update, patch for User.
  router.route('/me')
    .all(authMiddleware.requiresAuth({ addUserId: true }))
    .get(
      //userDetailValidators.retrieve,
      userDetailController.retrieve
    )
    .post(
      //userDetailValidators.update,
      userDetailController.update
    )
    .put(
      //userDetailValidators.patch,
      userDetailController.patch
    );

  // Get, update, patch, delete.
  router.route('/:user_id')
    .all(authMiddleware.requiresAuth())
    .get(
      //userDetailValidators.retrieve,
      requiresPermission('retrieve'),
      userDetailController.retrieve
    )
    .post(
      //userDetailValidators.update,
      requiresPermission('update'),
      userDetailController.update
    )
    .put(
      //userDetailValidators.patch,
      requiresPermission('patch'),
      userDetailController.patch
    )
    .delete(
      //userDetailValidators.retrieve,
      requiresPermission('delete'),
      userDetailController.remove
    );

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(), 
      //userDetailValidators.create,
      requiresPermission('create'),
      userDetailController.create
    )

  app.use('/api/v1/userdetails', router);

}
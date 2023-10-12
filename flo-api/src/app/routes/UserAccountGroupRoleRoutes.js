import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let UserAccountGroupRoleController = require('../controllers/UserAccountGroupRoleController');

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);

  let router = express.Router();
  let requiresPermission = checkPermissions('UserAccountGroupRole');


  // Archive.
  router.route('/archive/:user_id/:group_id')
    .delete(
      authMiddleware.requiresAuth(),
      //userAccountGroupRoleValidators.archive,
      requiresPermission('archive'),
      UserAccountGroupRoleController.archive);

  // Query by user_id.
  router.route('/userid/:user_id')
    .get(
      authMiddleware.requiresAuth(),
      //userAccountGroupRoleValidators.retrieveByUserId,
      requiresPermission('queryPartition'),
      UserAccountGroupRoleController.retrieveByUserId
    );


  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      UserAccountGroupRoleController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:user_id/:group_id')
    .get(
      authMiddleware.requiresAuth(),
      //userAccountGroupRoleValidators.retrieve,
      requiresPermission('retrieve'),
      UserAccountGroupRoleController.retrieve
    )
    .post(
      authMiddleware.requiresAuth(),
      //userAccountGroupRoleValidators.update,
      requiresPermission('update'),
      UserAccountGroupRoleController.update
    )
    .put(
      authMiddleware.requiresAuth(),
      //userAccountGroupRoleValidators.patch,
      requiresPermission('patch'),
      UserAccountGroupRoleController.patch
    )
    .delete(
      authMiddleware.requiresAuth(),
      //userAccountGroupRoleValidators.remove,
      requiresPermission('remove'),
      UserAccountGroupRoleController.remove
    );

  // Create
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //userAccountGroupRoleValidators.create,
      requiresPermission('create'),
      UserAccountGroupRoleController.create
    );

  app.use('/api/v1/useraccountgrouproles', router);

}
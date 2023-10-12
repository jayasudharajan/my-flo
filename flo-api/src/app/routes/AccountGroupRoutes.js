import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let AccountGroupController = require('../controllers/AccountGroupController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('AccountGroup');
  let getGroupId = req => new Promise((resolve) => resolve(req.params.id));

  // Archive.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //accountGroupValidators.archive,
      requiresPermission('archive'),
      AccountGroupController.archive);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      AccountGroupController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .get(
      authMiddleware.requiresAuth(),
      //accountGroupValidators.retrieve,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieve',
          get: getGroupId
        }
      ]),
      AccountGroupController.retrieve
    )
    .post(
      authMiddleware.requiresAuth(),
      //accountGroupValidators.update,
      requiresPermission('update'),
      AccountGroupController.update
    )
    .put(
      authMiddleware.requiresAuth(),
      //accountGroupValidators.patch,
      requiresPermission('patch'),
      AccountGroupController.patch
    )
    .delete(
      authMiddleware.requiresAuth(),
      //accountGroupValidators.remove,
      requiresPermission('remove'),
      AccountGroupController.remove
    );

  // Create
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //accountGroupValidators.create,
      requiresPermission('create'),
      AccountGroupController.create
    );

  app.use('/api/v1/accountgroups', router);

}
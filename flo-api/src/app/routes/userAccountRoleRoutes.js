import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let userAccountRoleController = require('../controllers/userAccountRoleController');

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('UserAccountRole');

  // Faux delete.
  router.route('/archive/:user_id/:account_id')
    .delete(
      authMiddleware.requiresAuth(),
      //userAccountRoleValidators.archive,
      requiresPermission('archive'),
      userAccountRoleController.archive);

  // Get by Account.
  router.route('/account/:account_id')
    .get(
      authMiddleware.requiresAuth(),
      //userAccountRoleValidators.retrieveByAccountId,
      requiresPermission('retrieveByAccount'),
      userAccountRoleController.retrieveByAccountId)

  // Get, update, patch, delete.
  router.route('/:user_id/:account_id')
    .all(authMiddleware.requiresAuth())
    .get(
      //userAccountRoleValidators.retrieve,
      requiresPermission('retrieve'),
      userAccountRoleController.retrieve)
    .post(
      //userAccountRoleValidators.update,
      requiresPermission('update'),
      userAccountRoleController.update)
    .put(
      //userAccountRoleValidators.patch,
      requiresPermission('patch'),
      userAccountRoleController.patch)
    .delete(
      //userAccountRoleValidators.remove,
      requiresPermission('delete'),
      userAccountRoleController.remove);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      userAccountRoleController.scan);  // For testing only!!!

  // Get by User.
  router.route('/:user_id')
    .get(
      authMiddleware.requiresAuth(),
      //userAccountRoleValidators.retrieveByUserId,
      requiresPermission('retrieveByUser'),
      userAccountRoleController.retrieveByUserId)

  // Create, scan.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //userAccountRoleValidators.create,
      requiresPermission('create'),
      userAccountRoleController.create)

  app.use('/api/v1/useraccountroles', router);

}
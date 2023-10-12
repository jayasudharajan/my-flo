import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let userLocationRoleController = require('../controllers/userLocationRoleController');

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('UserLocationRole');

  // Faux delete.
  router.route('/archive/:user_id/:location_id')
    .delete(
      authMiddleware.requiresAuth(),
      //userLocationRoleValidators.archive,
      requiresPermission('archive'),
      userLocationRoleController.archive);

  // Get by Location.
  router.route('/location/:location_id')
    .get(
      authMiddleware.requiresAuth(),
      //userLocationRoleValidators.retrieveByLocationId,
      requiresPermission('retrieveByLocation'),
      userLocationRoleController.retrieveByLocationId);

  // Get, update, patch, delete.
  router.route('/:user_id/:location_id')
    .all(authMiddleware.requiresAuth())
    .get(
      //userLocationRoleValidators.retrieve,
      requiresPermission('retrieve'),
      userLocationRoleController.retrieve)
    .post(
      //userLocationRoleValidators.update,
      requiresPermission('update'),
      userLocationRoleController.update)
    .put(
      //userLocationRoleValidators.patch,
      requiresPermission('patch'),
      userLocationRoleController.patch)
    .delete(
      //userLocationRoleValidators.remove,
      requiresPermission('remove'),
      userLocationRoleController.remove);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      userLocationRoleController.scan);  // For testing only!!!

  // Get by User.
  router.route('/:user_id')
    .get(
      authMiddleware.requiresAuth(),
      //userLocationRoleValidators.retrieveByUserId,
      requiresPermission('retrieveByUser'),
      userLocationRoleController.retrieveByUserId);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //userLocationRoleValidators.create,
      requiresPermission('create'),
      userLocationRoleController.create);

  app.use('/api/v1/userlocationroles', router);

}
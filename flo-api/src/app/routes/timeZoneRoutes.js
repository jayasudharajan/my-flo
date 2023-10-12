import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let timeZoneController = require('../controllers/timeZoneController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('TimeZone');

  // Faux delete.
  router.route('/archive/:tz')
    .delete(
      authMiddleware.requiresAuth(),
      //timeZoneValidators.archive,
      requiresPermission('archive'),
      timeZoneController.archive);

  // Get ALL active timezones.
  router.route('/active')
    .get(
      //requiresAuth(),
      //requiresPermission('retrieveActive'),
      timeZoneController.retrieveActive
    );

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      timeZoneController.scan);  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:tz')
    .all(authMiddleware.requiresAuth())
    .get(
      //timeZoneValidators.retrieve,
      requiresPermission('retrieve'),
      timeZoneController.retrieve)
    .post(
      //timeZoneValidators.update,
      requiresPermission('update'),
      timeZoneController.update)
    .put(
      //timeZoneValidators.patch,
      requiresPermission('patch'),
      timeZoneController.patch)
    .delete(
      //timeZoneValidators.remove,
      requiresPermission('delete'),
      timeZoneController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //timeZoneValidators.create,
      requiresPermission('create'),
      timeZoneController.create);

  app.use('/api/v1/timezones', router);

}

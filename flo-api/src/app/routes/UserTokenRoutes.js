import express from 'express';
import { requiresAuth } from '../middleware/auth';
import { checkPermissions } from '../middleware/acl';

let UserTokenController = require('../controllers/UserTokenController');

export default (app, appContainer) => {
  let router = express.Router();
  let requiresPermission = checkPermissions('UserToken');

  router.route('/me')
    .get(
      requiresAuth(),
      UserTokenController.retrieveOwn
    );

  // // Archive.
  // router.route('/archive/:user_id/:time_issued')
  //   .delete(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('archive'),
  //     UserTokenController.archive);

  // // Query by user_id.
  // router.route('/userid/:user_id')
  //   .get(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('queryPartition'),
  //     UserTokenController.retrieveByUserId
  //   );


  // router.route('/scan')
  //   .get(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('scan'),
  //     UserTokenController.scan);  // For testing only!!!

  // // Get, update, patch, delete.
  // router.route('/:user_id/:time_issued')
  //   .get(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('retrieve'),
  //     UserTokenController.retrieve
  //   )
  //   .post(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('update'),
  //     UserTokenController.update
  //   )
  //   .put(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('patch'),
  //     UserTokenController.patch
  //   )
  //   .delete(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('remove'),
  //     UserTokenController.remove
  //   );

  // // Create
  // router.route('/')
  //   .post(
  //     authMiddleware.requiresAuth(),
  //     requiresPermission('create'),
  //     UserTokenController.create
  //   );

  app.use('/api/v1/usertokens', router);

}
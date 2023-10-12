import express from 'express';
import AuthMiddleware from '../services/utils/AuthMiddleware';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByUserId } from '../../util/accountGroupUtils';

let userUtilsController = require('../controllers/userUtilsController');

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('UserUtils');
  let getUserId = req => new Promise((resolve) => resolve(req.params.user_id));
  let getGroupIdByUserId = req => lookupByUserId(req.params.user_id, req.log);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      //userUtilsValidators.scanWholeUser,
      userUtilsController.scanWholeUser);

  router.route('/search')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('search'),
      userUtilsController.search);

  // Get ICDs by specific account.
  router.route('/account/:account_id/icds')
    .get(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.retrieveICDsbyAccountId,
      requiresPermission('retrieveICDsByAccount'),
      userUtilsController.retrieveICDsbyAccountId);

  // Get ICDs by specific user.
  router.route('/user/:user_id/icds')
    .get(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.retrieveICDsbyUserId,
      requiresPermission('retrieveICDsByUser'),
      userUtilsController.retrieveICDsbyUserId);

  router.route('/email/:email/user')
    .get(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.searchUserByEmail,
      requiresPermission('retrieveByEmail'),
      userUtilsController.searchUserByEmail);

  // Get Users by specific device id.
  router.route('/icd/:device_id/users')
    .get(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.retrieveUsersbyDeviceId,
      requiresPermission('retrieveUsersByDevice'),
      userUtilsController.retrieveUsersbyDeviceId);

  // Get ALL Users for ALL devices?  <-- TODO: Review.
  router.route('/icd/users')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveAllUsersByDevice'),
      userUtilsController.retrieveUsersbyDeviceId);

  router.route('/group_id/:group_id/users')
    .get(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.retrieveUserByGroup,
      userUtilsController.retrieveUserByGroup);

  router.route('/group_id/:group_id/users/search')
    .get(
      authMiddleware.requiresAuth(),
      userUtilsController.searchUserInGroup);

  router.route('/group_id/:group_id/icd/users')
    .get(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.retrieveUserICDByGroup,
      userUtilsController.retrieveUserICDByGroup);

  // Create a new Account, Location, and set Roles for a User.
  router.route('/newaccount')
    .post(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.createNewAccount,
      requiresPermission('createNewAccount'),
      userUtilsController.createNewAccount);

  // Get, update whole user.
  router.route('/:user_id')
    .all(authMiddleware.requiresAuth())
    .get(
      //userUtilsValidators.retrieveWholeUser,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveWholeUser',
          get: getGroupIdByUserId
        }
      ]),
      userUtilsController.retrieveWholeUser)
    .put(
      //userUtilsValidators.patchWholeUser,
      requiresPermission('patchWholeUser'),
      userUtilsController.patchWholeUser)
    .delete(
      //userUtilsValidators.removeWholeUser,
      requiresPermission('removeWholeUser'),
      userUtilsController.removeWholeUser);

  // Create whole user.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //userUtilsValidators.createWholeUser,
      requiresPermission('createWholeUser'),
      userUtilsController.createWholeUser);

  app.use('/api/v1/userutils', router);

}

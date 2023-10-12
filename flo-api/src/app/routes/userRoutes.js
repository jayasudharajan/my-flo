import express from 'express';
import AuthMiddleware from '../services/utils/AuthMiddleware';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByUserId } from '../../util/accountGroupUtils';
import passport from 'passport';

let userController = require('../controllers/userController');

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('User');
  let getUserId = req => new Promise((resolve) => resolve(req.params.user_id));
  let getGroupIdByUserId = req => lookupByUserId(req.params.user_id, req.log);

  router.route('/me/resetpassword')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      userController.resetPassword
    );
  
  router.route('/:user_id/resetpassword')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('resetPassword', getUserId),
      userController.resetPassword
    );
  
  // Validate Registration.
  router.route('/register/:token1/:token2')
    .get(
      //userValidators.retrieveRegistrationDetails,
      userController.retrieveRegistrationDetails
    );

  // Retrieve by email.
  router.route('/email/:email')
    .get(
      authMiddleware.requiresAuth(),
      //userValidators.getUserByEmail,
      requiresPermission('retrieveByEmail'),
      userController.getUserByEmail);


  // Scan ResetToken.  
  router.route('/resettokens')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scanResetToken'),
      userController.scanResetToken);


  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      userController.scan);  // For testing only!!!

  // Logout.
  // router.route('/logout/:notification_token')
  //   .post(userController.logoutWithToken);

  // router.route('/logout/:notification_token')
  //   .all(authMiddleware.requiresAuth())
  //   .post(
  //     authMiddleware.requiresAuth({ addUserId: true }),
  //     userController.logout)

  router.route('/logout')
    .all(authMiddleware.requiresAuth())
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //userValidators.logout,
      userController.logout
    );

  router.route('/:user_id/lock')
    .all(authMiddleware.requiresAuth())
    .post(
      requiresPermission('updateLockStatus'),
      userController.updateLockStatus
    )
    .get(
      requiresPermission('retrieveLockStatus'),
      userController.retrieveLockStatus
    );

  // Get 'UI Permissions' User.
  router.route('/uip')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      userController.getUIPermissions
    );

  // Basic login.
  router.route('/auth')
    .post(
      //userValidators.authenticate,
      userController.authenticate
    );

  router.route('/auth/mfa')
    .post(
      passport.authenticate('mfa', { session: false }),
      userController.performMFAChallenge
    );

  // Forgot password.
  router.route('/requestreset')
    .post(
      //userValidators.requestPasswordReset,
      userController.requestPasswordReset
    );

  router.route('/requestreset/user')
    .post(
      //userValidators.requestPasswordResetUser,
      userController.requestPasswordResetUser
    );
  // Validate Password Reset.
  router.route('/requestreset/:user_id/:token')
    .get(
      //userValidators.validateResetToken,
      userController.validateResetToken
    );
  
  router.route('/resettokens')
    .get(
      authMiddleware.requiresAuth(),
      userController.scanResetToken);


  // Get, update, patch for User.
  router.route('/me')
    .all(authMiddleware.requiresAuth({ addUserId: true }))
    .get(
      //userValidators.retrieve,
      userController.retrieve)
    .post(
      //userValidators.update,
      userController.update)
    .put(
      //userValidators.patch,
      userController.patch);


  // Send Registration email.
  router.route('/sendregistration')
    .post(
      authMiddleware.requiresAuth(),
      //userValidators.sendRegistrationMail,
      requiresPermission('sendRegistrationMail'),
      userController.sendRegistrationMail
    );


  // Save Registration.
  router.route('/register')
    .post(
      //userValidators.saveRegistration,
      userController.saveRegistration);


  // Faux delete.
  router.route('/archive/:user_id')
    .delete(
      authMiddleware.requiresAuth(),
      //userValidators.archive,
      requiresPermission('archive'),
      userController.archive
    );

  // Get, update, patch, delete.
  router.route('/:user_id')
    .all(authMiddleware.requiresAuth())
    .get(
      //userValidators.retrieve,
      requiresPermissions([
        {
          resource: 'User',
          permission: 'retrieve',
          get: getUserId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveUser',
          get: getGroupIdByUserId
        }
      ]),
      userController.retrieve
    )
    .post(
      //userValidators.update,
      requiresPermissions([
        {
          resource: 'User',
          permission: 'update',
          get: getUserId
        },
        {
          resource: 'AccountGroup',
          permission: 'updateUser',
          get: getGroupIdByUserId
        }
      ]),      
      userController.update
    )
    .put(
      //userValidators.patch,
      requiresPermissions([
        {
          resource: 'User',
          permission: 'patch',
          get: getUserId
        },
        {
          resource: 'AccountGroup',
          permission: 'patchUser',
          get: getGroupIdByUserId
        }
      ]),
      userController.patch
    )
    .delete(
      //userValidators.remove,
      requiresPermissions([
        {
          resource: 'User',
          permission: 'delete',
          get: getUserId
        },
        {
          resource: 'AccountGroup',
          permission: 'deleteUser',
          get: getGroupIdByUserId
        }
      ]),
      userController.remove
    );

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //userValidators.create,
      requiresPermission('create'),
      userController.create
    )

  /*
  // Review: why is this repeated?  Don't we need param?
  router.route('/')
    .delete(
      authMiddleware.requiresAuth(),
      requiresPermission('archive'), 
      userController.archive
    );
  */

  app.use('/api/v1/users', router);

}
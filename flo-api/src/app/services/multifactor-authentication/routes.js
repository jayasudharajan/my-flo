import express from 'express';
import DIFactory from '../../../util/DIFactory';
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import MultifactorAuthenticationController from './MultifactorAuthenticationController';
import passport from 'passport';

class MultifactorAuthenticationRouter {
  constructor(authMiddleware, aclMiddleware, multifactorAuthenticationController) {
    this.authMiddleware = authMiddleware;
    this.aclMiddleware = aclMiddleware;
    this.multifactorAuthenticationController = multifactorAuthenticationController;

    this.router = express.Router();

    this.router.route('/:user_id')
      .get(
        authMiddleware.requiresAuth(),
        aclMiddleware.requiresPermissions([
          {
            resource: 'User',
            permission: 'retrieveMFASettings',
            get: ({ params: { user_id } }) => Promise.resolve(user_id)
          }
        ]),
        (...args) => this.multifactorAuthenticationController.retrieveUserMFASettings(...args)
      )
      .post(
        authMiddleware.requiresAuth(),
        aclMiddleware.requiresPermissions([
          {
            resource: 'User',
            permission: 'createMFASettings',
            get: ({ params: { user_id } }) => Promise.resolve(user_id)
          }
        ]),
        (...args) => this.multifactorAuthenticationController.createUserMFASettings(...args)
      )
      .put(
        authMiddleware.requiresAuth(),
        aclMiddleware.requiresPermissions([
          {
            resource: 'User',
            permission: 'createMFASettings',
            get: ({ params: { user_id } }) => Promise.resolve(user_id)
          }
        ]),
        (...args) => this.multifactorAuthenticationController.ensureUserMFASettings(...args)
      );

    this.router.route('/:user_id/enable')
      .post(
        authMiddleware.requiresAuth(),
        aclMiddleware.requiresPermissions([
          {
            resource: 'User',
            permission: 'enableMFA',
            get: ({ params: { user_id } }) => Promise.resolve(user_id)
          }
        ]),
        (...args) => this.multifactorAuthenticationController.enableMFA(...args)
      );

    this.router.route('/:user_id/disable')
      .post(
        authMiddleware.requiresAuth(),
        aclMiddleware.requiresPermissions([
          {
            resource: 'User',
            permission: 'disableMFA',
            get: ({ params: { user_id } }) => Promise.resolve(user_id)
          }
        ]),
        (...args) => this.multifactorAuthenticationController.disableMFA(...args)
      );
  }
}

export default new DIFactory(MultifactorAuthenticationRouter, [AuthMiddleware, ACLMiddleware, MultifactorAuthenticationController]);
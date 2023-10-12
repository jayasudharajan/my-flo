import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByAccountId, lookupByUserId } from '../../util/accountGroupUtils';
import AccountRouterV1_5 from '../services/account-v1_5/routes';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let accountController = require('../controllers/accountController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('Account');
  let getAccountId = req => new Promise((resolve) => resolve(req.params.id));
  let getGroupId = req => new Promise((resolve) => resolve(req.params.group_id));
  let getGroupIdByAccountId = req => lookupByAccountId(req.params.id, req.log);
  let getGroupIdByUserId = req => lookupByUserId(req.params.owner_user_id, req.log);

  // Faux delete.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //accountValidators.archive,
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'archive'
        },
        {
          resource: 'AccountGroup',
          get: getGroupIdByAccountId
        }
      ]),
      accountController.archive
    );

  // Retrieve by group.
  router.route('/group/:group_id')
    .get(
      authMiddleware.requiresAuth(),
      //accountValidators.retrieveAccountsForGroup,
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'retrieveByGroup'
        },
        {
          resource: 'retrieveAccountByGroup',
          get: getGroupId
        }
      ]),
      accountController.retrieveAccountsForGroup
    );

  // Retrieve by owner user.
  router.route('/user/:owner_user_id')
    .get(
      authMiddleware.requiresAuth(),
      //accountValidators.retrieveAccountsForOwner,
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'retrieveByOwner'
        },
        {
          resource: 'retrieveAccountByOwner',
          get: getGroupIdByUserId
        }
      ]),
      accountController.retrieveAccountsForOwner
    );

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      accountController.scan
    );  // For testing only!!!

  // Get, update, patch, delete.
  router.route('/:id')
    .all(authMiddleware.requiresAuth())
    .get(
      //accountValidators.retrieve,
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'retrieve'
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveAccount',
          get: getGroupIdByAccountId
        }
      ]),
      accountController.retrieve
    )
    .post(
      //accountValidators.update,
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'update'
        },
        {
          resource: 'AccountGroup',
          permission: 'updateAccount',
          get: getGroupIdByAccountId
        }
      ]),
      accountController.update
    )
    .put(
      //accountValidators.patch,
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'patch'
        },
        {
          resource: 'AccountGroup',
          permission: 'patchAccount',
          get: getGroupIdByAccountId
        }
      ]),
      accountController.patch
    )
    .delete(
      //accountValidators.remove,
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'remove'
        },
        {
          resource: 'AccountGroup',
          permission: 'removeAccount',
          get: getGroupIdByAccountId
        }
      ]),
      accountController.remove
    );

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //accountValidators.create,
      requiresPermission('create'),
      accountController.create
    );

  app.use('/api/v1/accounts', router);
  app.use('/api/v1_5/accounts', new AccountRouterV1_5(authMiddleware).routes());
}
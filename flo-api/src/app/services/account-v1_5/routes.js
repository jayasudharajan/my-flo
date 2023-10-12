import express from 'express';
import { requiresPermissions } from '../../middleware/acl';
import { lookupByAccountId, lookupByUserId } from '../../../util/accountGroupUtils';
import * as requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import AccountController from './AccountController';
import container from './container';

class AccountRouter {
  constructor(authMiddleware) {
    const controller = container.get(AccountController);
    const router = express.Router();
    this.router = router;

    router.route('/archive/:id')
      .delete(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.archive),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'archive'
          },
          {
            resource: 'AccountGroup',
            permission: 'archiveAccount',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.archive(...args)
      );

    router.route('/:id')
      .all(authMiddleware.requiresAuth())
      .get(
        reqValidate(requestTypes.retrieve),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'retrieve'
          },
          {
            resourse: 'AccountGroup',
            permission: 'retrieveAccount',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.retrieve(...args)
      )
      .post(
        reqValidate(requestTypes.update),
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
        (...args) => controller.update(...args)
      )
      .put(
        reqValidate(requestTypes.patch),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'update'
          },
          {
            resource: 'AccountGroup',
            permission: 'patchAccount',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.patch(...args)
      )
      .delete(
        reqValidate(requestTypes.remove),
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
        (...args) => controller.remove(...args)
      );

    router.route('/')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.create),
        requiresPermissions('create'),
        (...args) => controller.create(...args)
      );


    router.route('/group/:group_id')
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.retrieveByGroupId),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'retrieveByGroupId'
          },
          {
            resource: 'AccountGroup',
            permission: 'retrieveAccountByGroupId',
            get: getGroupId
          }
        ]),
        (...args) => controller.retrieveByGroupId(...args)
      );

    router.route('/user/:owner_user_id')
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.retrieveByOwnerUserId),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'retrieveByOwnerUserId'
          },
          {
            resource: 'AccountGroup',
            permission: 'retrieveAccountByOwnerUserId',
            get: getUserId
          }
        ]),
        (...args) => controller.retrieveByOwnerUserId(...args)
      );
  }

  routes() {
    return this.router;
  }
}

function getGroupIdByAccountId(req) {
	return lookupByAccountId(req.params.id, req.log);
}

function getGroupId(req) {
	return Promise.resolve(req.params.group_id);
}

function getUserId(req) {
	return Promise.resolve(req.params.owner_user_id);
}

export default AccountRouter;
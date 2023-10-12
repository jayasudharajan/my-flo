import express from 'express';
import { requiresPermissions } from '../../middleware/acl';
import { lookupByLocationId, lookupByAccountId } from '../../../util/accountGroupUtils';
import * as requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import LocationController from './LocationController';
import container from './container';

class LocationRouter {
  constructor(authMiddleware) {
    const router = express.Router();
    const controller = container.get(LocationController);
    this.router = router;

    router.route('/archive/:account_id/:location_id')
      .delete(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.archive),
        requiresPermissions([
          {
            resource: 'Location',
            permission: 'archive'
          },
          {
            resource: 'AccountGroup',
            permission: 'archiveLocation',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.archive(...args)
      );

    router.route('/:account_id/:location_id')
      .all(authMiddleware.requiresAuth())
      .get(
        reqValidate(requestTypes.retrieve),
        requiresPermissions([
          {
            resource: 'Location',
            permission: 'retrieve',
            get: getLocationId
          },
          {
            resource: 'AccountGroup',
            permission: 'retrieveLocation',
            getGroupIdByAccountId
          }
        ]),
        (...args) => controller.retrieve(...args)
      )
      .post(
        reqValidate(requestTypes.update),
        requiresPermissions([
          {
            resource: 'Location',
            permission: 'update',
            get: getLocationId
          },
          {
            resource: 'AccountGroup',
            permission: 'updateLocation',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.update(...args)
      )
      .put(
        reqValidate(requestTypes.patch),
        requiresPermissions([
          {
            resource: 'Location',
            permission: 'patch',
            get: getLocationId
          },
          {
            resource: 'AccountGroup',
            permission: 'patchLocation',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.patch(...args)
      )
      .delete(
        reqValidate(requestTypes.remove),
        requiresPermissions([
          {
            resource: 'Location',
            permission: 'remove',
            get: getLocationId
          },
          {
            resource: 'AccountGroup',
            permission: 'removeLocation',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.remove(...args)
      );

    router.route('/')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.create),
        requiresPermissions([
          {
            resource: 'Location',
            permission: 'create'
          }
        ]),
        (...args) => controller.create(...args)
      );

    router.route('/location/:location_id')
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.retrieveByLocationId),
        requiresPermissions([
          {
            resource: 'Location',
            permission: 'retrieveByLocationId'
          },
          {
            resource: 'AccountGroup',
            permission: 'retrieveLocationByLocationId',
            get: getGroupIdByLocationId
          }
        ]),
        (...args) => controller.retrieveByLocationId(...args)
      );

    router.route('/:account_id')
      .all(authMiddleware.requiresAuth())
      .get(
        reqValidate(requestTypes.retrieveByAccountId),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'retrieveByAccountId',
            get: getAccountId
          },
          {
            resource: 'AccountGroup',
            permission: 'retrieveLocationByAccountId',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.retrieveByAccountId(...args)
      )
      .post(
        reqValidate(requestTypes.createByAccountId),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'createLocationByAccountId',
            get: getAccountId
          },
          {
            resource: 'AccountGroup',
            permission: 'createLocationByAccountId',
            get: getGroupIdByAccountId
          }
        ]),
        (...args) => controller.createByAccountId(...args)
      );

    router.route('/me')
      .all(authMiddleware.requiresAuth({ addAccountId: true }))
      .get(
        reqValidate(requestTypes.retrieveByAccountId),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'retrieveByAccountId',
            get: getAccountId
          }
        ]),
        (...args) => controller.retrieveByAccountId(...args)
      )
      .post(
        reqValidate(requestTypes.createLocationByAccountId),
        requiresPermissions([
          {
            resource: 'Account',
            permission: 'createLocationByAccountId',
            get: getAccountId
          }
        ]),
        (...args) => controller.createLocationByAccountId(...args)
      );
  }

  routes() {
    return this.router;
  }
}

function getGroupIdByAccountId(req) {
  return lookupByAccountId(req.params.account_id, req.log);
}

function getGroupIdByLocationId(req) {
  return lookupByLocationId(req.params.location_id, req.log);
}

function getLocationId(req) {
  return Promise.resolve(req.params.location_id);
}

function getAccountId(req) {
  return Promise.resolve(req.params.account_id);
}

export default LocationRouter;

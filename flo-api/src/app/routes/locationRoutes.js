import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByLocationId, lookupByAccountId } from '../../util/accountGroupUtils';
import LocationRouterV1_5 from '../services/location-v1_5/routes';
import AuthMiddleware from '../services/utils/AuthMiddleware';
import reqValidate from '../middleware/reqValidate';
import TLocation from '../services/location-v1_5/models/TLocation';
import tcustom from '../models/definitions/CustomTypes'; 
import { createPartialValidator } from '../../util/validationUtils';
import t from 'tcomb-validation';

let locationController = require('../controllers/locationController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresLocationPermission = checkPermissions('Location');
  let requiresAccountPermission = checkPermissions('Account');
  let getLocationId = req => new Promise((resolve) => resolve(req.params.location_id));
  let getAccountId = req => new Promise((resolve) => resolve(req.params.account_id));
  let getGroupIdByLocationId = req => lookupByLocationId(req.params.location_id, req.log);
  let getGroupIdByAccountId = req => lookupByAccountId(req.params.account_id, req.log);

  const validateUpdate = reqValidate({
    params: t.struct({
      account_id: tcustom.UUIDv4,
      location_id: tcustom.UUIDv4
    }),
    body: TLocation
  });

  const validatePatch = reqValidate({
    params: t.struct({
      account_id: tcustom.UUIDv4,
      location_id: tcustom.UUIDv4
    }),
    body: createPartialValidator(TLocation)
  });

  const validateCreate = reqValidate({
    body: TLocation
  });

    //Enumeration
    router.route('/enums')
        .get(
            authMiddleware.requiresAuth(),
            locationController.retrieveLocationEnumeration
        );
  // Faux delete.
  router.route('/archive/:account_id/:location_id')
    .delete(
      authMiddleware.requiresAuth(),
      //locationValidators.archive,
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
      locationController.archive
    );

  // Get by Location.
  router.route('/location/:location_id')
    .get(
      authMiddleware.requiresAuth(),
      //locationValidators.retrieveByLocationId,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'retrieveByLocationId',
          get: getLocationId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveLocationByLocationId',
          get: getGroupIdByLocationId
        }
      ]),
      locationController.retrieveByLocationId
    );

  // Get, update, patch, delete.
  router.route('/:account_id/:location_id')
    .all(authMiddleware.requiresAuth())
    .get(
      //locationValidators.retrieve,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'retrieve',
          get: getLocationId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveLocation',
          get: getGroupIdByLocationId
        }
      ]),
      locationController.retrieve
    )
    .post(
      //locationValidators.update,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'update',
          get: getLocationId
        },
        {
          resource: 'AccountGroup',
          permission: 'updateLocation',
          get: getGroupIdByLocationId
        }
      ]),
      validateUpdate,
      locationController.update
    )
    .put(
      //locationValidators.patch,
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'patch',
          get: getLocationId
        },
        {
          resource: 'AccountGroup',
          permission: 'patchLocation',
          get: getGroupIdByLocationId
        }
      ]),
      validatePatch,
      locationController.patch
    )
    .delete(
      //locationValidators.remove,
      requiresLocationPermission('remove', getLocationId),
      locationController.remove
    );

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresLocationPermission('scan'),
      locationController.scan
    );  // For testing only!!!

  // Get, update, patch for User.
  router.route('/me')
    .all(authMiddleware.requiresAuth({ addAccountId: true, addLocationId: true }))
    .get(
      //locationValidators.retrieve,
      locationController.retrieve
    )
    .post(
      //locationValidators.update,
      validateUpdate,
      locationController.update
    )
    .put(
      //locationValidators.patch,
      validatePatch,
      locationController.patch
    );

  // Get by Account.
  router.route('/:account_id')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'Account',
          permission: 'retrieveByAccount',
          get: getAccountId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveLocationByAccount',
          get: getGroupIdByAccountId
        }
      ]),
      locationController.retrieveByAccountId
    );

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //locationValidators.create,
      validateCreate,
      requiresLocationPermission('create'),
      locationController.create
    );

  app.use('/api/v1/locations', router);
  app.use('/api/v1_5/locations', new LocationRouterV1_5(authMiddleware).routes());
}
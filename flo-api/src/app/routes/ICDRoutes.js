import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByDeviceId } from '../../util/icdUtils';
import { lookupByLocationId } from '../../util/accountGroupUtils';
import ICDRouter from '../services/icd-v1_5/routes';
import containerUtils from '../../util/containerUtil';
import { appUsedMiddleware } from '../../util/httpUtil';
import AuthMiddleware from '../services/utils/AuthMiddleware';

const ICDController = require('../controllers/ICDController');

export default (app, container) => {

  // TODO: Look into why tests fail when the arguments to "mergeContainers" is reversed
  const authMiddleware = container.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ICD');
  let getLocationId = req => new Promise((resolve) => resolve(req.params.location_id));  
  let getLocationIdByDeviceId = req => lookupByDeviceId(req.params.device_id, req.log).then(({ location_id }) => location_id);
  let getGroupIdByLocationId = req => lookupByLocationId(req.params.location_id, req.log);
  let getGroupIdByDeviceId = req => lookupByDeviceId(req.params.device_id, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));
  const getGroupId = req => new Promise(resolve => resolve(req.params.group_id));

  router.route('/tz')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveByTimezone'),
      ICDController.retrieveByTimezone
    );

  // Get most severe alarm for the first ICD in a Location.
  router.route('/me/alarms/useraction')
    .post(
      authMiddleware.requiresAuth({ addLocationId: true, addUserId: true, addAccountId: true }), 
      //icdValidators.updateAlarmUserAction,
      ICDController.updateAlarmUserAction);

  // Get most severe alarm for the first ICD in a Location.
  router.route('/me/alarms/severe')
    .get(
      authMiddleware.requiresAuth({ addLocationId: true }), 
      //icdValidators.retrieveMostSevereAlarmByLocationId,
      ICDController.retrieveMostSevereAlarmByLocationId);

  // Clear all alarms for the first ICD in a Location.
  router.route('/me/alarms/clear')
    .post(
      authMiddleware.requiresAuth({ addLocationId: true, addUserId: true }), 
      //icdValidators.clearAlarmsByLocationId,
      ICDController.clearAlarmsByLocationId);

  // Get all alarms for the first ICD in a Location.
  router.route('/me/alarms/utc')
    .get(
      authMiddleware.requiresAuth({ addLocationId: true }),
      //icdValidators.retrieveAlarmsByLocationIdUTC,
      ICDController.retrieveAlarmsByLocationIdUTC);

  // Get all alarms for the first ICD in a Location.
  router.route('/me/alarms')
    .get(
      authMiddleware.requiresAuth({ addLocationId: true }), 
      //icdValidators.retrieveAlarmsByLocationId,
      ICDController.retrieveAlarmsByLocationId);

  // Get ICD based on Device ID.
  router.route('/device/:device_id')
    .get(
      authMiddleware.requiresAuth(),
      //icdValidators.retrieveByDeviceId,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveICDByDevice',
          get: getGroupIdByDeviceId
        },
        {
          resource: 'ICD',
          permission: 'retrieveByDevice'
        }
      ]),
      ICDController.retrieveByDeviceId);

  router.route('/device/:device_id/externalaction/:action_id')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermission('handleExternalAction'),
      ICDController.handleExternalAction
    );

  router.route('/device/:device_id/togglevalve/:valve_action/:action_id?')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'toggleValve',
          get: getLocationIdByDeviceId
        },
        {
          resource: 'ICD',
          permission: 'toggleValve'
        }
      ]),
      ICDController.toggleValve
    );

  router.route('/:icd_id/togglevalve/:valve_action/:action_id?')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'toggleValve',
          get: getLocationIdByDeviceId
        },
        {
          resource: 'ICD',
          permission: 'toggleValve'
        }
      ]),
      ICDController.toggleValve
    );

  router.route('/:icd_id/setsystemmode/:system_mode_id')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermissions([
        {
          resource: 'Location',
          permission: 'setSystemMode',
          get: getLocationIdByDeviceId
        },
        {
          resource: 'ICD',
          permission: 'setSystemMode'
        }
      ]),
      ICDController.toggleValve
    );

  // Get ICDs based on a Location.
  router.route('/location/:location_id')
    .get(
      authMiddleware.requiresAuth(),
      //icdValidators.retrieveByLocationId,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveICDByLocation',
          get: getGroupIdByLocationId
        },
        {
          resource: 'ICD',
          permission: 'retrieveByLocation'
        }
      ]),
      ICDController.retrieveByLocationId);

  // Get Users IDs based on Device.
  router.route('/users/:device_id')
    .get(
      authMiddleware.requiresAuth(),
      //icdValidators.retrieveUserIdsByDeviceId,
      requiresPermission('retrieveUsers'),
      ICDController.retrieveUserIdsByDeviceId);

  router.route('/user/icds/all')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('listAll'),
      ICDController.scanUserDevice);

  router.route('/user/icds/group/:group_id/all')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'listAllICD',
          get: getGroupId
        },
        {
          resource: 'ICD',
          permission: 'listAll'
        }
      ]),
      ICDController.fetchGroupUserDevice);

  router.route('/user/icds/search')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('listAll'),
      ICDController.searchUserDevices);

  router.route('/user/icds/group/:group_id/search')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'listAllICD',
          get: getGroupId
        },
        {
          resource: 'ICD',
          permission: 'listAll'
        }
      ]),
      ICDController.searchGroupUserDevices);

  // Faux delete.
  router.route('/archive/:id')
    .delete(
      authMiddleware.requiresAuth(),
      //icdValidators.archive,
      requiresPermission('archive'),
      ICDController.archive);

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('scan'),
      ICDController.scan);  // For testing only!!!

  // Get, update, patch for User.
  router.route('/me')
    .get(
      authMiddleware.requiresAuth({ addLocationId: true }), 
      //icdValidators.retrieveOne,
      ICDController.retrieveOne)
    .post(
      authMiddleware.requiresAuth({ addUserId: true, addLocationId: true }),
      ICDController.createOrUpdate);

  // Get, update, patch, delete.
  router.route('/:id')
    .all(authMiddleware.requiresAuth())
    .get(
      //icdValidators.retrieve,
      requiresPermission('retrieve'),
      ICDController.retrieve)
    .post(
      //icdValidators.update,
      requiresPermission('update'),
      ICDController.update)
    .put(
      //icdValidators.patch,
      requiresPermission('patch'),
      ICDController.patch)
    .delete(
      //icdValidators.remove,
      requiresPermission('delete'),
      ICDController.remove);

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      //icdValidators.create,
      requiresPermission('create'),
      ICDController.create);

  app.use('/api/v1/icds', router);

}
import express from 'express';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let userAlarmNotificationDeliveryRuleController = require('../controllers/userAlarmNotificationDeliveryRuleController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('UserAlarmNotificationDeliveryRule');
  const getUserId = req => new Promise((resolve) => resolve(req.params.user_id));


  // Get Rules for each User by location, alarm_id, system_mode.
  router.route('/users/:location_id/:alarm_id/:system_mode')
    .get(
      authMiddleware.requiresAuth(), 
      //userAlarmNotificationDeliveryRuleValidators.retrieveByLocationIdAlarmIdSystemMode,
      requiresPermission('retrieveByLocationAlarmIdSystemMode'),
      userAlarmNotificationDeliveryRuleController.retrieveByLocationIdAlarmIdSystemMode);

  // Get, update, patch, delete.
  router.route('/:user_id/:location_id/:alarm_id/:system_mode')
    .all(authMiddleware.requiresAuth())
    .get(
      //userAlarmNotificationDeliveryRuleValidators.retrieve,
      requiresPermissions([
        {
          resource: 'UserAlarmNotificationDeliveryRule',
          permission: 'retrieve'
        },
        {
          resource: 'User',
          permission: 'retrieveUserAlarmNotificationDeliveryRule',
          get: getUserId
        }
      ]),
      userAlarmNotificationDeliveryRuleController.retrieve)
    .post(
      //userAlarmNotificationDeliveryRuleValidators.update,
      requiresPermissions([
        {
          resource: 'UserAlarmNotificationDeliveryRule',
          permission: 'update'
        },
        {
          resource: 'User',
          permission: 'updateUserAlarmNotificationDeliveryRule',
          get: getUserId
        }
      ]),
      userAlarmNotificationDeliveryRuleController.update)
    .put(
      //userAlarmNotificationDeliveryRuleValidators.patch,
      requiresPermissions([
        {
          resource: 'UserAlarmNotificationDeliveryRule',
          permission: 'patch'
        },
        {
          resource: 'User',
          permission: 'patchUserAlarmNotificationDeliveryRule',
          get: getUserId
        }
      ]),
      userAlarmNotificationDeliveryRuleController.patch)
    .delete(
      //userAlarmNotificationDeliveryRuleValidators.remove,
      requiresPermissions([
        {
          resource: 'UserAlarmNotificationDeliveryRule',
          permission: 'remove'
        },
        {
          resource: 'User',
          permission: 'removeUserAlarmNotificationDeliveryRule',
          get: getUserId
        }
      ]),
      userAlarmNotificationDeliveryRuleController.remove);

  // Get Rules for each User by Location and Alarm.
  router.route('/users/:location_id/:alarm_id')
    .get(
      authMiddleware.requiresAuth(), 
      //userAlarmNotificationDeliveryRuleValidators.retrieveByLocationIdAlarmId,
      requiresPermission('retrieveByLocationAlarm'),
      userAlarmNotificationDeliveryRuleController.retrieveByLocationIdAlarmId);

  // Get all by User and Location.
  router.route('/userlocation/:user_id/:location_id')
    .get(
      authMiddleware.requiresAuth(), 
      //userAlarmNotificationDeliveryRuleValidators.retrieveByUserIdLocationId,
      requiresPermissions([
        {
          resource: 'UserAlarmNotificationDeliveryRule',
          permission: 'retrieveByUserLocation'
        }, 
        {
          resource: 'User',
          permission: 'retrieveUserAlarmNotificationDeliveryRuleByUserLocation',
          get: getUserId
        }
      ]),
      userAlarmNotificationDeliveryRuleController.retrieveByUserIdLocationId
    );

  // Get all for a User.
  router.route('/user/:user_id')
    .get(
      authMiddleware.requiresAuth(), 
      //userAlarmNotificationDeliveryRuleValidators.retrieveByUserId,
      requiresPermissions([
        {
          resource: 'UserAlarmNotificationDeliveryRule',
          permission: 'retrieveByUser'
        }, 
        {
          resource: 'User',
          permission: 'retrieveUserAlarmNotificationDeliveryRuleByUser',
          get: getUserId
        }
      ]),
      userAlarmNotificationDeliveryRuleController.retrieveByUserId
    );

  router.route('/scan')
    .get(
      authMiddleware.requiresAuth(), 
      requiresPermission('scan'),
      userAlarmNotificationDeliveryRuleController.scan);  // For testing only!!!

  // Create.
  router.route('/')
    .post(
      authMiddleware.requiresAuth(), 
      requiresPermissions([
        {
          resource: 'UserAlarmNotificationDeliveryRule',
          permission: 'create'
        },
        {
          resource: 'User',
          permission: 'createUserAlarmNotificationDeliveryRule',
          get: req => Promise.resolve( req.body.user_id )
        }
      ]),
      userAlarmNotificationDeliveryRuleController.create)

  app.use('/api/v1/useralarmnotificationdeliveryrules', router);

}

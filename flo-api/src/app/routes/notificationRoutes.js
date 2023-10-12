const  express = require( 'express');
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByICDId } from '../../util/icdUtils';
import AuthMiddleware from '../services/utils/AuthMiddleware';

const notificationController = require('../controllers/notificationController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('Location');
  let getLocationId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => location_id);
  const getUserId = ({ params: { user_id }}) => new Promise(resolve => resolve(user_id));

  router.route('/deliveryrules/user/:user_id')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'User',
          permission: 'retrieveDeliveryRules',
          get: getUserId
        }
      ]),
      notificationController.retrieveDeliveryRules
    );

  router.route('/icd/:icd_id/pending')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingNotifications', getLocationId),
      notificationController.retrievePendingNotifications
    )
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingNotifications', getLocationId),
      notificationController.retrievePendingNotifications
    );

  router.route('/icd/:icd_id/cleared')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveClearedNotifications', getLocationId),
      notificationController.retrieveClearedNotifications
    )
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveClearedNotifications', getLocationId),
      notificationController.retrieveClearedNotifications
    );

  router.route('/icd/:icd_id/clear')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermission('clearNotifications', getLocationId),
      notificationController.clearNotifications
    );

  router.route('/icd/:icd_id/pending/severity')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingSeverityBySeverity', getLocationId),
      notificationController.retrievePendingSeverityBySeverity
    )
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingSeverityBySeverity', getLocationId),
      notificationController.retrievePendingSeverityBySeverity
    );

  router.route('/icd/:icd_id/pending/alarmid')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingNotifications', getLocationId),
      notificationController.retrievePendingNotificationsByAlarmIdSystemMode
    )
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingNotifications', getLocationId),
      notificationController.retrievePendingNotificationsByAlarmIdSystemMode
    );

  router.route('/icd/:icd_id/pending/severity/alarmid')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingNotifications', getLocationId),
      notificationController.retrievePendingNotificationsBySeverityAndAlarmIdSystemMode
    )
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('retrievePendingNotifications', getLocationId),
      notificationController.retrievePendingNotificationsBySeverityAndAlarmIdSystemMode
    );

  router.route('/icd/:icd_id')
    .all(
      authMiddleware.requiresAuth(),
      requiresPermissions([
       {
        resource: 'Location',
        permission: 'retrieveFullActivityLog',
        get: getLocationId
       }
      ])
    )
    .get(
      notificationController.retrieveFullActivityLog
    )
    .post(
      notificationController.retrieveFullActivityLog
    );

  router.route('/group/:group_id/icd/:icd_id')
    .all(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveFullActivityLog'
        }
      ])
    )
    .get(
      notificationController.retrieveGroupFullActivityLog
    )
    .post(
      notificationController.retrieveGroupFullActivityLog
    );

  router.route('/analytics')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveAnalytics'),
      notificationController.retrieveAnalytics
    )
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveAnalytics'),
      notificationController.retrieveAnalytics
    );

  router.route('/group/:group_id/pending/location')
    .all(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrievePendingNotifications',
          get: ({ params: { group_id } }) => Promise.resolve(group_id)
        }
      ])
    )
    .get(
      notificationController.retrievePendingGroupAlertsByLocation
    )
    .post(
      notificationController.retrievePendingGroupAlertsByLocation
    );

  router.route('/dailyleaktestresults')
    .all(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveDailyLeakTestResult')
    )
    .post(
      notificationController.retrieveDailyLeakTestResult
    );

  router.route('/group/:group_id/analytics/daily')
    .all(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'AccountGroup',
          permission: 'retrieveDailyAlertCountByGroupId',
          get: ({ params: { group_id } }) => Promise.resolve(group_id)
        }
      ])
    )
    .get(
      notificationController.retrieveDailyAlertCountByGroupId
    )
    .post(
      notificationController.retrieveDailyAlertCountByGroupId
    );

  app.use('/api/v1/alerts', router);
  app.use('/api/v1/notifications', router);
}

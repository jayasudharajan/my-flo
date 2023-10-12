var  express = require( 'express');
import AuthMiddleware from '../services/utils/AuthMiddleware';
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByDeviceId, lookupByICDId } from '../../util/icdUtils';
import { lookupByLocationId } from '../../util/accountGroupUtils';

var waterFlowController = require('../controllers/waterFlowController');

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('Location');
  const getLocationIdByDeviceId = req => lookupByDeviceId(req.params.device_id, req.log).then(({ location_id }) => location_id);
  const getGroupIdByDeviceId = req => lookupByDeviceId(req.params.device_id, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));
  const getLocationIdByICDId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => location_id);
  const getGroupIdByICDId = req => lookupByICDId(req.params.icd_id, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));


  router.route('/today/total/:device_id')
    .get(
      authMiddleware.requiresAuth(),
      //waterFlowValidators.retrieveDailyTotalWaterFlow,
      requiresPermission('retrieveDailyWaterFlow', getLocationIdByDeviceId),
      waterFlowController.retrieveDailyTotalWaterFlow);

  router.route('/today/:device_id')
    .get(
      authMiddleware.requiresAuth(),
      //waterFlowValidators.retrieveDailyWaterFlow,
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveDailyWaterFlow',
          get: getLocationIdByDeviceId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveDailyWaterFlow',
          get: getGroupIdByDeviceId
        },
        {
          resource: 'Waterflow',
          permission: 'retrieveDailyWaterFlow',
          get: getLocationIdByDeviceId
        }
      ]),
      waterFlowController.retrieveDailyWaterFlow);

  router.route('/monthlyusage/:device_id')
    .get(
      authMiddleware.requiresAuth(),
      //waterFlowValidators.retrieveMonthlyUsage,
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByDeviceId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByDeviceId
        }
      ]),
      waterFlowController.retrieveMonthlyUsage);

  router.route('/consumption/icd/:icd_id/last_24_hours')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast24HoursConsumption
    );

  router.route('/consumption/icd/:icd_id/last_30_days')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast30DaysConsumption
    );

  router.route('/consumption/icd/:icd_id/last_12_months')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast12MonthsConsumption
    );

  router.route('/averages/icd/:icd_id/last_24_hours')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast24HourlyAvgs
    );

  router.route('/consumption/icd/:icd_id/last_week')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLastWeekConsumption
    );

  router.route('/consumption/icd/:icd_id/last_28_days')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast28DaysConsumption
    );

  router.route('/consumption/icd/:icd_id/last_day')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLastDayConsumption
    );


  // NOTE: this also assumes ONE location/device.
  // Is done via location. Should we track it by device?
  router.route('/me/dailygoal')
    .get(
      authMiddleware.requiresAuth({ addAccountId: true, addLocationId: true }),
      waterFlowController.retrieveDailyGoal);

  router.route('/devices')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'Waterflow',
          permission: 'retrieveTransmittingDevices'
        }
      ]),
      waterFlowController.retrieveTransmittingDevices
    );

  router.route('/rates/device/:device_id/last_day')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'Waterflow',
          permission: 'retrieveTransmittingDevices'
        }
      ]),
      waterFlowController.retrieveLast24HoursTransmissionRateHourlyByDeviceId
    );

  router.route('/measurement/icd/:icd_id/last_day')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLastDayMeasurements
    );

  router.route('/measurement/icd/:icd_id/last_week')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLastWeekMeasurements
    );

  router.route('/measurement/icd/:icd_id/this_week')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveThisWeekMeasurements
    );


  router.route('/measurement/icd/:icd_id/last_28_days')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast28DaysMeasurements
    );

  router.route('/measurement/icd/:icd_id/last_12_months')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast12MonthsMeasurements
    );

  router.route('/measurement/group/:group_id/this_week')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrieveThisWeekMeasurements',
          get: ({ params: { group_id } }) => Promise.resolve(group_id)
        }
      ]),
      waterFlowController.retrieveThisWeekMeasurementsByGroupId
    );

  router.route('/measurement/icd/:icd_id/last_24_hours')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermissions([
        { 
          resource: 'Location',
          permission: 'retrieveMonthlyUsage',
          get: getLocationIdByICDId
        },
        {
          resource: 'AccountGroup',
          permission: 'retrieveMonthlyUsage',
          get: getGroupIdByICDId
        }
      ]),
      waterFlowController.retrieveLast24HoursMeasurements
    );

  app.use('/api/v1/waterflow', router);

}

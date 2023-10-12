var  express = require( 'express');
import { checkPermissions, requiresPermissions } from '../middleware/acl';
import { lookupByDeviceId } from '../../util/icdUtils';
import { lookupByLocationId } from '../../util/accountGroupUtils';
import AuthMiddleware from '../services/utils/AuthMiddleware';

var mqttController = require('../controllers/mqttController');

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('Location');
  let getLocationId = req => lookupByDeviceId(req.params.deviceid, req.log).then(({ location_id }) => location_id);
  let getGroupIdByICDId = req => lookupByDeviceId(req.params.deviceid, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));

  router.route('/client/togglevalve/:deviceid/:valveaction')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.toggleValve,
      requiresPermission('toggleValve', getLocationId),
      mqttController.toggleValve);

  router.route('/client/powerreset/:deviceid')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.powerReset,
      requiresPermission('powerReset', getLocationId),
      mqttController.powerReset
    );

  router.route('/client/setsystemmode/:deviceid')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.setSystemMode,
      requiresPermission('setSystemMode', getLocationId),
      mqttController.setSystemMode);

  router.route('/client/requestupgrade/:deviceid')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.requestUpgrade,
      requiresPermission('requestUpgrade', getLocationId),
      mqttController.requestUpgrade);

  router.route('/client/zittest/:deviceid')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.runZitTest,
      requiresPermission('runZit', getLocationId),
      mqttController.runZitTest);

  router.route('/client/factoryreset/:deviceid')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.factoryReset,
      requiresPermission('factoryReset', getLocationId),
      mqttController.factoryReset
    );

  router.route('/client/profile/:deviceid')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.updateProfileParameters,
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'updatemqttProfile',
          get: getGroupIdByICDId
        },
        {
          resource: 'mqtt',
          permission: 'updateProfile'
        }
      ]),
      mqttController.updateProfileParameters
    )
    .get(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermissions([
        {
          resource: 'AccountGroup',
          permission: 'retrievemqttProfile',
          get: getGroupIdByICDId
        },
        {
          resource: 'mqtt',
          permission: 'retrieveProfile'
        }
      ]),
      mqttController.getProfileParameters
    );

  router.route('/client/sleep/:deviceid')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.sleep,
      requiresPermission('sleepSetSystemMode', getLocationId),
      mqttController.sleep
    );

  router.route('/client/forcedsleep/:deviceid/enable')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.enableForcedSleep,
      requiresPermission('enableForcedSleep'),
      mqttController.enableForcedSleep
    );

  router.route('/client/forcedsleep/:deviceid/disable')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      //mqttValidators.disableForcedSleep,
      requiresPermission('disableForcedSleep'),
      mqttController.disableForcedSleep
    );

  router.route('/client/version/:deviceid')
    .get(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermission('getVersion', getLocationId),
      mqttController.getVersion
    );

  router.route('/perms')
    .get(
      authMiddleware.requiresAuth({ addLocationId: true }),
      mqttController.retrievePermissions
    );

  app.use('/api/v1/mqtt', router);

}


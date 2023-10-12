var  express = require( 'express');
import { checkPermissions } from '../middleware/acl';
import { lookupByDeviceId } from '../../util/icdUtils';
import { lookupByLocationId } from '../../util/accountGroupUtils';
import AuthMiddleware from '../services/utils/AuthMiddleware';

var pesController = require('../controllers/pesController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('PES');
  let getGroupIdByDeviceId = req => lookupByDeviceId(req.params.device_id, req.log).then(({ location_id }) => lookupByLocationId(location_id, req.log));

  // TODO: add Group Admin permissions.

  //POST /devices/3722D53B19D1/accept_params/

  router.route('/devices/:device_id/accept')
    .post(
      authMiddleware.requiresAuth(),
      //pesValidators.acceptParams,
      requiresPermission('acceptParams'),
      pesController.acceptParams);

  router.route('/devices/:device_id/reject')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('rejectParams'),
      pesController.rejectParams
    );

  router.route('/devices/:device_id/deploy')
    .post(
      authMiddleware.requiresAuth({ addUserId: true }),
      requiresPermission('deployParams'),
      pesController.deployParams
    );

  router.route('/devices/:device_id')
    .all(authMiddleware.requiresAuth())
    .get(
      requiresPermission('retrieveDevice'),
      pesController.retrieveDevice
    )
    .delete(
      //pesValidators.deleteDevice,
      requiresPermission('deleteDevice'),
      pesController.deleteDevice
    );

  router.route('/devices')
    .all(authMiddleware.requiresAuth())
    .get(
      requiresPermission('listDevices'),
      pesController.listDevices)
    .post(
      //pesValidators.addDevice,
      requiresPermission('addDevice'),
      pesController.addDevice);

  router.route('/proposed/:param_id')
    .get(
      authMiddleware.requiresAuth(),
      //pesValidators.retrieveParams,
      requiresPermission('retrieveParams'),
      pesController.retrieveParams);

  router.route('/proposed')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveProposedParamsList'),
      pesController.retrieveProposedParamsList);

  router.route('/proposed_user')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveProposedParamsUserList'),
      pesController.retrieveProposedParamsUserList);

  router.route('/compute')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('forceCompute'),
      pesController.forceCompute);    

  app.use('/api/v1/pes', router);

}

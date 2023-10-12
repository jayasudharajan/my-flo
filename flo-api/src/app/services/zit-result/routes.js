import express from 'express';
import { checkPermissions }  from '../../middleware/acl';
import ZITResultController from './ZITResultController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import container from './container';

class ZitResultRouter {
  constructor(authMiddleware) {
    const router = express.Router();
    const requiresPermission = checkPermissions('ZITResult');
    const controller = container.get(ZITResultController);
    this.router = router;

    // Query by icd_id.
    router.route('/icd/:icd_id')
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.retrieveByIcdId),
        requiresPermission('retrieveByIcdId'),
        controller.retrieveByIcdId.bind(controller)
      );

    router.route('/device/:device_id')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.createByDeviceId),
        requiresPermission('create'),
        controller.createByDeviceId.bind(controller)
      )
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.retrieveByDeviceId),
        requiresPermission('retrieveByDeviceId'),
        controller.retrieveByDeviceId.bind(controller)
      );

		// Get
		router.route('/:icd_id/:round_id')
			.get(
        authMiddleware.requiresAuth(),
				reqValidate(requestTypes.retrieve),
				requiresPermission('retrieve'),
				controller.retrieve.bind(controller)
			);
  }

  routes() {
    return this.router;
  }
}

export default ZitResultRouter;
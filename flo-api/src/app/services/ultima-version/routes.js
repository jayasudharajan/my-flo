import express from 'express';
import { checkPermissions }  from '../../middleware/acl';
import UltimaVersionController from './UltimaVersionController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import container from './container';

class UltimaVersionRouter {

  constructor(authMiddleware) {
    const router = express.Router();
    const requiresPermission = checkPermissions('UltimaVersion');
    const controller = container.get(UltimaVersionController);
    this.router = router;

		// Get, update, delete.
    router.route('/:model/:version')
      .all(authMiddleware.requiresAuth())
      .get(
        reqValidate(requestTypes.retrieve),
        requiresPermission('retrieve'),
        controller.retrieve.bind(controller))
      .post(
        reqValidate(requestTypes.update),
        requiresPermission('update'),
        controller.update.bind(controller))
      .put(
        reqValidate(requestTypes.patch),
        requiresPermission('patch'),
        controller.patch.bind(controller))
      .delete(
        reqValidate(requestTypes.delete),
        requiresPermission('delete'),
        controller.remove.bind(controller));

    router.route('/scan')
      .get(
        authMiddleware.requiresAuth(),
        requiresPermission('scan'),
        controller.scan.bind(controller));  // For testing only!!!

		// Get by model.
    router.route('/:model')
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.queryPartition),
        requiresPermission('retrieveByModel'),
        controller.retrieveByModel.bind(controller));

		// Create.
    router.route('/')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.create),
        requiresPermission('create'),
        controller.create.bind(controller));
  }

  routes() {
    return this.router;
  }
}

export default UltimaVersionRouter;
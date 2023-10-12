import express from 'express';
import StockICDController from './StockICDController';
import AuthMiddleware from '../utils/AuthMiddleware'
import ACLMiddleware from '../utils/ACLMiddleware'
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from  '../../../util/DIFactory';

class StockICDRouter {

	constructor(controller, authMiddleware, aclMiddleware) {
		const router = express.Router();
		const requiresPermission = aclMiddleware.checkPermissions('StockICD');
		this.router = router;

		router.route('/generate')
			.post(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.generate),
				requiresPermission('generate'),
				controller.generateStockICD.bind(controller)
			);

    router.route('/remove-from-pki')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.removeFromPki),
        requiresPermission('remove-from-pki'),
        controller.removeFromPki.bind(controller)
      );
    
    router.route('/registration/device/:device_id')
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.retrieveRegistrationByDeviceId),
        requiresPermission('retrieve'),
        controller.retrieveRegistrationByDeviceId.bind(controller)
      );

		// Retrieve only Qr Code
		router.route('/:id/qrcode')
			.get(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.retrieveQrCodeById),
				requiresPermission('retrieve'),
				controller.retrieveQrCode.bind(controller)
			);

		router.route('/device/:device_id/qrcode')
			.get(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.retrieveQrCodeByDeviceId),
				requiresPermission('retrieveQrCode'),
				controller.retrieveQrCodeByDeviceId.bind(controller)
			);

    router.route('/device/:device_id/qrdata')
      .get(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.retrieveQrDataByDeviceId),
        requiresPermission('retrieve'),
        controller.retrieveQrDataByDeviceId.bind(controller)
      );
    
		router.route('/device/:device_id/token')
			.get(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.retrieveWebSocketTokenByDeviceId),
				requiresPermission('retrieveQrCode'), // TODO Change this to `retrieveWebSocketTokenByDeviceId` once permission is created by Helmut.
				controller.retrieveWebSocketTokenByDeviceId.bind(controller)
			);

		// Create.
		router.route('/')
			.post(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.create),
				requiresPermission('create'),
				controller.create.bind(controller)
			);

    router.route('/sn')
      .all(authMiddleware.requiresAuth())
      .post(
        reqValidate(requestTypes.generateSerialNumber),
        requiresPermission('generateSerialNumber'),
        controller.generateSerialNumber.bind(controller)
      )
      .get(
        reqValidate(requestTypes.retrieveSerialNumberByDeviceId),
        requiresPermission('retrieveSerialNumberByDeviceId'),
        controller.retrieveSerialNumberByDeviceId.bind(controller)
      )
      .delete(
        reqValidate(requestTypes.removeSerialNumberByDeviceId),
        requiresPermission('removeSerialNumber'),
        controller.removeSerialNumberByDeviceId.bind(controller)
      );

    router.route('/sn/:sn')
      .all(authMiddleware.requiresAuth())
      .get(
        reqValidate(requestTypes.retrieveSerialNumberBySN),
        requiresPermission('retrieveSerialNumber'),
        controller.retrieveSerialNumberBySN.bind(controller)
      )
      .delete(
        reqValidate(requestTypes.removeSerialNumberBySN),
        requiresPermission('removeSerialNumber'),
        controller.removeSerialNumberBySN.bind(controller)
      );

		// Get, update, patch, delete.
		router.route('/:id')
			.all(authMiddleware.requiresAuth())
			.get(
				reqValidate(requestTypes.retrieve),
				requiresPermission('retrieve'),
				controller.retrieve.bind(controller)
			)
			.post(
				reqValidate(requestTypes.update),
				requiresPermission('update'),
				controller.update.bind(controller)
			)
			.put(
				reqValidate(requestTypes.patch),
				requiresPermission('patch'),
				controller.patch.bind(controller)
			)
			.delete(
				reqValidate(requestTypes.delete),
				requiresPermission('delete'),
				controller.remove.bind(controller)
			);

		// Faux delete.
		router.route('/archive/:id')
			.delete(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.archive),
				requiresPermission('archive'),
				controller.archive.bind(controller)
			);
	}

	routes() {
		return this.router;
	}
}

export default new DIFactory(StockICDRouter, [ StockICDController, AuthMiddleware, ACLMiddleware ]);





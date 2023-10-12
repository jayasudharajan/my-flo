import NotificationTokenController from './NotificationTokenController';
import { replaceMeWithUserId } from '../../middleware/auth';
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import reqValidate from '../../middleware/reqValidate';
import requestTypes from './models/requestTypes';
import DIFactory from  '../../../util/DIFactory';
import express from 'express';

class NotificationTokenRouter {
	constructor(authMiddleware, aclMiddleware, controller) {
		const router = express.Router();
		const requiresAuth = (...args) => authMiddleware.requiresAuth(...args);
		const requiresPermission = aclMiddleware.checkPermissions('User');
		const getUserId = req => new Promise(resolve => resolve(req.params.user_id));

		this.router = router;

		router.route('/archive/:user_id')
			.post(
				requiresAuth(),
				reqValidate(requestTypes.archive),
				requiresPermission('archiveNotificationToken'),
				controller.archive.bind(controller)
			);

		router.route('/:user_id')
			.all(
				requiresAuth(),
				replaceMeWithUserId('user_id'),
			)
			.get(
				reqValidate(requestTypes.retrieve),
				aclMiddleware.requiresPermissions([
					{
						resource: 'NotificationToken',
						permission: 'retrieve'
					},
					{
						resource: 'User',
						permission: 'retrieveNotificationToken', 
						get: getUserId
					}]),
				controller.retrieve.bind(controller)
			)
			.post(
				reqValidate(requestTypes.update),
				requiresPermission('updateNotificationToken', getUserId),
				controller.update.bind(controller)
			)
			.put(
				reqValidate(requestTypes.patch),
				requiresPermission('patchNotificationToken', getUserId),
				controller.patch.bind(controller)
			)
			.delete(
				reqValidate(requestTypes.delete),
				requiresPermission('removeNotificationToken', getUserId),
				controller.remove.bind(controller)
			);

		router.route('/:user_id/addtoken')
			.post(
				requiresAuth(),
				replaceMeWithUserId('user_id'),
				reqValidate(requestTypes.addToken),
				requiresPermission('addNotificationToken', getUserId),
				controller.addToken.bind(controller)
			);

		router.route('/:user_id/removetoken')
			.post(
				requiresAuth(),
				replaceMeWithUserId('user_id'),
				reqValidate(requestTypes.removeToken),
				requiresPermission('removeNotificationToken', getUserId),
				controller.removeToken.bind(controller)
			);
	}
}

export default DIFactory(NotificationTokenRouter, [AuthMiddleware, ACLMiddleware, NotificationTokenController]);

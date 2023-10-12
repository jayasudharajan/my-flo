import passport from 'passport';
import express from 'express';
import DIFactory from '../../../util/DIFactory';
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import PasswordlessController from './PasswordlessController';

class PasswordlessRouter {
	constructor(authMiddleware, aclMiddleware, passwordlessController) {
		this.passwordlessController = passwordlessController;

		this.router = express.Router();

		this.router.route('/start')
			.post(
				passport.authenticate(['client-password'], { session: false }),
				(...args) => this.passwordlessController.sendMagicLink(...args)
			);

		this.router.route('/:user_id/:passwordless_token')
			.get(
				authMiddleware.requiresAuth(),
				aclMiddleware.requiresPermissions([{
					resource: 'Passwordless',
					permission: 'redirectWithMagicLink',
					get: ({ params: { user_id, passwordless_token } }) => Promise.resolve(`${ user_id}:${ passwordless_token }`)
				}]),
				(...args) => this.passwordlessController.redirectWithMagicLink(...args)
			)
			.post(
				authMiddleware.requiresAuth(),
				passport.authenticate('client-password', { session: false }),
				aclMiddleware.requiresPermissions([{
					resource: 'Passwordless',
					permission: 'loginWithMagicLink',
					get: ({ params: { user_id, passwordless_token } }) => Promise.resolve(`${ user_id }:${ passwordless_token }`)
				}]),
				(...args) => this.passwordlessController.loginWithMagicLink(...args)
			);
	}
}

export default new DIFactory(PasswordlessRouter, [AuthMiddleware, ACLMiddleware, PasswordlessController]);
import express from 'express';
import UserRegistrationController from './UserRegistrationController'
import DIFactory from  '../../../util/DIFactory';
import reqValidate from '../../middleware/reqValidate';
import TMobileUserRegistrationData from './models/TMobileUserRegistrationData';
import TWebUserRegistrationData from './models/TWebUserRegistrationData';
import passport from 'passport';
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import t from 'tcomb-validation';

class UserRegistrationRouter {
	constructor(userRegistrationController, authMiddleware, aclMiddleware) {
		this.userRegistrationController = userRegistrationController;
		this.router = express.Router();

		this.router.route('/')
			.post(
				reqValidate({ body: TMobileUserRegistrationData }),
				(...args) => this.userRegistrationController.acceptTermsAndSendVerificationEmailFromMobile(...args)
			)
			.get(
				authMiddleware.requiresAuth(),
				aclMiddleware.requiresPermissions([{
					resource: 'User',
					permission: 'retrieveRegistrationToken'
				}]),
				reqValidate({ query: t.struct({ email: t.String }) }),
				(...args) => this.userRegistrationController.retrieveRegistrationTokenByEmail(...args)
			);

		this.router.route('/register/web')
			.post(
				reqValidate({ body: TWebUserRegistrationData }),
				(...args) => this.userRegistrationController.acceptTermsAndSendVerificationEmailFromWeb(...args)
			);

		this.router.route('/verify')
			.post((...args) => this.userRegistrationController.verifyEmailAndCreateUser(...args));

		this.router.route('/verify/oauth2')
			.post(
				passport.authenticate(['client-basic', 'client-password'], { session: false }),
				(...args) => this.userRegistrationController.verifyEmailAndCreateUserWithOAuth2(...args)
			);
			
		this.router.route('/email')
			.post((...args) => this.userRegistrationController.checkEmailAvailability(...args));

		this.router.route('/resend')
			.post((...args) => this.userRegistrationController.resendVerificationEmail(...args));

	}
}

export default new DIFactory(UserRegistrationRouter, [UserRegistrationController, AuthMiddleware, ACLMiddleware]);
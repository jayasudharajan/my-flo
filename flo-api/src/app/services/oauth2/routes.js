import express from 'express';
import DIFactory from '../../../util/DIFactory';
import AuthMiddleware from '../utils/AuthMiddleware';
import OAuth2Controller from './OAuth2Controller';
import passport from 'passport';


class OAuth2Router {
	constructor(authMiddleware, oauth2Controller) {
		this.oauth2Controller = oauth2Controller;
		this.authMiddleware = authMiddleware;

		this.router = express.Router();

		this.router.route('/authorize')
			.all(
				this.authMiddleware.requiresAuth()
			)
			.get(
				(...args) => this.oauth2Controller.retrieveAuthorizationDetails(...args)
			)
			.post(
				(...args) => this.oauth2Controller.authorize(...args)
			);

		this.router.route('/token')
            .all(
                /** Double Secret Hack for Alexa. SEE: https://gpgdigital.atlassian.net/browse/DT-355 **/
                this.authMiddleware.swapClientSecret()
            )
			.post(
				passport.authenticate(['client-basic', 'client-password'], { session: false }),
				(...args) => this.oauth2Controller.issueToken(...args)
			);
	}
}

export default new DIFactory(OAuth2Router, [AuthMiddleware, OAuth2Controller]);
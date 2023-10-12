import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';
import UserRegistrationService from './UserRegistrationService';
import UserRegistrationConfig from './UserRegistrationConfig';
import TRegistrationFlow from './models/TRegistrationFlow';


class UserRegistrationController {
	constructor(userRegistrationService, userRegistrationConfig) {
		this.userRegistrationService = userRegistrationService;
		this.userRegistrationConfig = userRegistrationConfig;
	}

	checkEmailAvailability({ body: { email } }) {
		return this.userRegistrationService.checkEmailAvailability(email);
	}

	acceptTermsAndSendVerificationEmailFromMobile(req) {
		const { body: data } = req;
		//const ipAddress = req.get('X-Forwarded-For');

		return this.userRegistrationService.acceptTermsAndSendVerificationEmail(data, TRegistrationFlow.mobile)
			.then(() => true);
	}

	acceptTermsAndSendVerificationEmailFromWeb(req) {
		const { body: data } = req;

		return this.userRegistrationService.acceptTermsAndSendVerificationEmail(data, TRegistrationFlow.web)
			.then(() => true);
	}

	verifyEmailAndCreateUser({ body: { token } }) {
		// Verify and login will be separated in the future
		// but due to time constraints, we are doing them together
		return this.userRegistrationService.verifyEmailAndCreateUser(token)
			.then(() => this.userRegistrationService.loginUserWithLegacyAuth(token));
	}

	verifyEmailAndCreateUserWithOAuth2({ user: client, body: { token } }) {
		return this.userRegistrationService.verifyEmailAndCreateUser(token)
			.then(() => this.userRegistrationService.loginUserWithOAuth2(token, client));
	}

	resendVerificationEmail({ body: { email } }) {
		return this.userRegistrationService.resendVerificationEmail(email)
			.then(() => true);
	}

	retrieveRegistrationTokenByEmail({ query: { email } }) {

		return this.userRegistrationService.retrieveRegistrationTokenByEmail(email);
	}
}

export default new DIFactory(new ControllerWrapper(UserRegistrationController), [UserRegistrationService, UserRegistrationConfig]);
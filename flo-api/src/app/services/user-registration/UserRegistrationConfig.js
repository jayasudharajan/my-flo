class UserRegistrationConfig {
	constructor(config) {
		this.config = config;
	}

	getUserRegistrationTokenTTL() {
		return Promise.resolve(this.config.registrationTokenTTL);
	}

	getUserRegistrationTokenSecret() {
		return Promise.resolve(this.config.tokenSecret);
	}

	getMobileUserRegistrationEmailTemplateId(locale) {
		if (locale && locale.toLowerCase().trim().startsWith('fr')) {
			return Promise.resolve(this.config.frenchMobileEmailTemplateId);
		}

		return Promise.resolve(this.config.registrationEmailTemplateId);
	}

	getWebUserRegistrationEmailTemplateId(locale) {
		// if (locale.toLowerCase().trim().startsWith('fr')) {
		// 	return Promise.resolve(this.config.frenchWebEmailTemplateId);
		// }

		return Promise.resolve(this.config.webRegistrationEmailTemplateId)
	}

	getUserRegistrationDataTTL() {
		return Promise.resolve(this.config.registrationDataTTL);
	}

	getUserRegistrationRedirectURL() {
		return Promise.resolve(this.config.registrationRedirectURL)
	}
}

export default UserRegistrationConfig;
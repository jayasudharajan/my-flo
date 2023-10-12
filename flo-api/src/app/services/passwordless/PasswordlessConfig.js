
class PasswordlessConfig {
	constructor(config) {
		this.config = config;
	}

	getMagicLinkTemplateId() {
		return Promise.resolve(this.config.magicLinkEmailTemplateId);
	}

	getRedirectURL() {
		return Promise.resolve(this.config.passwordlessRedirectURL);
	}

	getMagicLinkMobileURI() {
		return Promise.resolve(this.config.magicLinkMobileURI);
	}

	getPasswordlessClientId() {
		return Promise.resolve(this.config.oauth2ClientId);
	}
}

export default PasswordlessConfig;
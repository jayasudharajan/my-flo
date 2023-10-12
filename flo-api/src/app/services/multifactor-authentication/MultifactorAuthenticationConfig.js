
export default class MultifactorAuthenticationConfig {
	constructor(config) {
	 this.config = config;
	}

	getMFATokenTTL() {
	 return Promise.resolve(this.config.mfaTokenTTL);
	}

	getMFATokenSecret() {
	 return Promise.resolve(this.config.tokenSecret);
	}
}
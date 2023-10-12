export default class OAuth2Config {
	constructor(config) {
		this.config = config;
	}
	
	getAccessTokenSecret() {
		return Promise.resolve(this.config.tokenSecret);
	}

	getRefreshTokenSecret() {
		return Promise.resolve(this.config.tokenSecret);
	}

	getAccessTokenTTL() {
		return Promise.resolve(this.config.accessTokenTTL);
	}

	getRefreshTokenTTL() {
		return Promise.resolve(this.config.refreshTokenTTL);
	}

	getRefreshTokenLimit() {
		return Promise.resolve(this.config.refreshTokenLimit);
	}

	getAuthorizationCodeTTL() {
		return Promise.resolve(this.config.authorizationCodeTTL);
	}

	getAuthorizationCodeSecret() {
		return Promise.resolve(this.config.tokenSecret);
	}

	getRefreshTokenLinger() {
		return Promise.resolve(this.config.refreshTokenLinger);
	}
}
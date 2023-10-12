
export default class EmailClientConfig {
	constructor(config) {
		this.config = config;
	}

	getApiKey() {
		return Promise.resolve(this.config.email.sendwithus.api_key);
	}

	getSenderAddress() {
		return Promise.resolve(this.config.email.sender);
	}

	getSenderName() {
		return Promise.resolve(this.config.email.company);
	}
}
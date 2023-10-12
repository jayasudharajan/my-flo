
module.exports = class EncryptionStrategyMock {

	constructor(secretKey) {
		this.secretKey = secretKey;
	}

	encrypt(data) {
		return Promise.resolve(data);
	}

	decrypt(data) {
		return Promise.resolve(data);
	}
}
import t from 'tcomb-validation';
import { floEncryption as ciphers } from 'flo-nodejs-encryption';
import DIFactory from  '../../../util/DIFactory';

class EncryptionStrategy {

	constructor(keyId, config) {
		const cipher = ciphers.floCipher();
		const keyProvider = ciphers.s3RSAKeyProvider(
			config.bucketRegion,
			config.bucketName,
			config.keyPathTemplate
		);

		this.keyId = keyId;
		this.pipeline = ciphers.encryptionPipeline(cipher, keyProvider, ciphers.keyIdRotationStrategy());
	}

	encrypt(data) {
		return this.pipeline.encrypt(this.keyId, data);
	}

	decrypt(data) {
		return this.pipeline.decrypt(data);
	}
}

export default EncryptionStrategy;
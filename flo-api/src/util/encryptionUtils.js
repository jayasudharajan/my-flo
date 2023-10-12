import config from '../config/config';

var ciphers = require('flo-nodejs-encryption').floEncryption;

function createEncryptionPipeline(serviceName) {
	let cipher = ciphers.floCipher();
	let keyProvider = ciphers.s3RSAKeyProvider(
		config.encryption.bucketRegion, 
		config.encryption.bucketName, 
		config.encryption[serviceName].keyPathTemplate
	);

	return ciphers.encryptionPipeline(cipher, keyProvider, ciphers.keyIdRotationStrategy());
}

var encryptionPipelines = {
	kafka: 	!config.encryption.kafka.encryptionEnabled ? null : createEncryptionPipeline('kafka'),
	dynamodb: !config.encryption.dynamodb.encryptionEnabled ? null : createEncryptionPipeline('dynamodb')
}; 

function ensureEncryptionPipeline(serviceName) {
	if (!encryptionPipelines[serviceName]) {
		encryptionPipelines[serviceName] = createEncryptionPipeline(serviceName);
	}
}

export function encrypt(serviceName, data) {

	 ensureEncryptionPipeline(serviceName);

	return encryptionPipelines[serviceName].encrypt(config.encryption[serviceName].keyId, data);
}

export function decrypt(serviceName, data) {

	ensureEncryptionPipeline(serviceName)

	return encryptionPipelines[serviceName].decrypt(data);
}

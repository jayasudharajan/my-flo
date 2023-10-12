const config = require('../config');
const ciphers = require('flo-nodejs-encryption').floEncryption;

const encryptionPipeline = ciphers.encryptionPipeline(
	ciphers.floCipher(),
	ciphers.s3RSAKeyProvider(
		config.s3.bucketRegion, 
		config.s3.bucketName, 
		config.s3.keyPathTemplate
	),
	ciphers.keyIdRotationStrategy()
);

module.exports = function (tableName, item) {
	const encryptedPropNames = config.encryptedTables[tableName.split('_').slice(1).join('')];

	if (encryptedPropNames && encryptedPropNames.length) {
		const promises = Object.keys(item || {})			
			.filter(propName => typeof item[propName] === 'string' || item[propName] instanceof String)
			.filter(propName => encryptedPropNames.indexOf(propName) >= 0)
			.map(propName => {
				if (item[propName].startsWith(config.dynamo.encryptionKeyId)) {
					return encryptionPipeline.decrypt(item[propName])
						.then(decryptedProp => [propName, decryptedProp]);
				} else {
					return Promise.resolve([propName, item[propName]]);
				}
			});

		return Promise.all(promises)
			.then(decryptedPropPairs => 
				decryptedPropPairs
					.reduce((acc, decryptedPropPair) => {
						return Object.assign(acc, { [decryptedPropPair[0]]: decryptedPropPair[1] });
					}, item)
			);
	} else {
		return new Promise(resolve => resolve(item));
	}
};
import DynamoTable from './DynamoTable';
import config from '../../config/config';
import { encrypt, decrypt } from '../../util/encryptionUtils';

export default class EncryptedDynamoTable extends DynamoTable {

	constructor(tableName, keyName, rangeName, encryptedProperties, dynamoDbClient, encryptionStrategy) {
		super(tableName, keyName, rangeName, dynamoDbClient);
		this.encryptedProperties = encryptedProperties;
		this.encryptionStrategy = encryptionStrategy || { encrypt: encrypt.bind(null, 'dynamodb') , decrypt: decrypt.bind(null, 'dynamodb') };
	}

	encryptProps(data) {
		return Promise.resolve(data);
	}

	decryptProps(data) {
		if (config.encryption.dynamodb.encryptionEnabled) {
			return processProps(this.encryptedProperties, data, data => {
				const encryptionKeyId = config.encryption.dynamodb.keyId;

				if (encryptionKeyId && data.startsWith(encryptionKeyId)) {
					return this.encryptionStrategy.decrypt(data);
				} else {
					return Promise.resolve(data);
				}
			});
		} else {
			return new Promise(resolve => resolve(data));
		}
	}

	decryptQuery(queryPromise) {
		return queryPromise
			.then(result => {
				if (result.Items && result.Items.length) {
				  let promises = result.Items.map(item => this.decryptProps(item));

				  return Promise.all(promises)
				    .then(decryptedItems => {
				      result.Items = decryptedItems;

				      return result;
				    })
				} else {
				  return result;
				}
			});
	}

	retrieve(...args) {
		return super.retrieve(...args)
			.then(result => {
				if (result.Item) {
					return this.decryptProps(result.Item)
						.then(decrypted => {
							result.Item = decrypted;

							return result;
						});
				} else {
					return result;
				}
			});
	}

	patch(keys, data) {
		return super.patch(keys, data)
			.then(result => {
				const { Attributes } = result;

				return this.decryptProps(Attributes)
					.then(decryptedAttributes => ({
						...result,
						Attributes: decryptedAttributes
					}));
			});
	}

	patchExisting(keys, data, returnValues) {
		return super.patchExisting(keys, data, returnValues)
			.then(result => {
				const { Attributes } = result;

				return this.decryptProps(Attributes)
					.then(decryptedAttributes => ({
						...result,
						Attributes: decryptedAttributes
					}));
			});
	}

	scanAll(limit, keys) {
		return this.decryptScan(super.scanAll(limit, keys));
	}

	scanActive() {
		return this.decryptScan(super.scanActive());			
	}

	decryptScan(scanPromise) {
		return scanPromise
			.then(result => {
				if (result.Items && result.Items.length) {
					let promises = result.Items.map(this.decryptProps.bind(this));

					return Promise.all(promises)
						.then(decryptedItems => {
							result.Items = decryptedItems;

							return result;
						});
				} else {
					return result;
				}
			});
	}

	marshal(data) {
		return this.encryptProps(data)
			.then(encrypted => super.marshal(encrypted));
	}

	marshalPatch(keys, data) {
		return this.encryptProps(data)
			.then(encrypted => super.marshalPatch(keys, encrypted));
	}

}

function processProps(encryptedProperties, data, operation) {
	let keys = Object.keys(data);
	let promises = keys
		.filter(key => encryptedProperties.indexOf(key) >= 0 && data[key])
		.map((key) => 
			operation(data[key])
				.then(processed => ({ key, processed }))
		);

	return Promise.all(promises)
		.then(processedProps => {
			let processedData = {};

			keys.forEach(key => processedData[key] = data[key]);
			processedProps.forEach(({ key, processed }) => processedData[key] = processed);

			return processedData;			
		});
}
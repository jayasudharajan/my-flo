var AWS = require('aws-sdk');
var ciphers = require('flo-nodejs-encryption').floEncryption;
var config = require('../src/config/config');
var tables = require('./tables.json');

var cipher = ciphers.floCipher();
var keyProvider = ciphers.s3RSAKeyProvider(
		config.aws.accessKeyId, 
		config.aws.secretAccessKey, 
		config.encryption.bucketRegion, 
		config.encryption.bucketName, 
		config.encryption.dynamodb.keyPathTemplate
);
var encryptionPipeline = ciphers.encryptionPipeline(cipher, keyProvider, ciphers.keyIdRotationStrategy());

var dynamodbClient = new AWS.DynamoDB.DocumentClient({
  accessKeyId: config.aws.accessKeyId,
  secretAccessKey: config.aws.secretAccessKey,
  region: config.aws.dynamodb.region,
  endpoint: config.aws.dynamodb.endpoint,
  apiVersion: config.aws.apiVersion
});


// ******************** MAIN ********************

tables
	.forEach(table => {
		encryptTable(table.tableName, table.pageSize, table.props);
	});

// *********************************************

function scan(params, cb) {
	dynamodbClient.scan(params).promise()
		.then(result => {
			console.log(result);
			if (result.Count) {
				var newParams = Object.keys(params)
					.reduce((acc, key) => {
						acc[key] = params[key];

						return acc;
					}, {});

				setTimeout(() => cb(result.Items), 0);
			} 

			if (result.LastEvaluatedKey) {
				newParams.ExclusiveStartKey = result.LastEvaluatedKey;

				scan(newParams, cb);
			}
		})
		.catch(err => console.log(err));
}

function encryptTable(tableName, pageSize, encryptedProperties) {
	scan({
		TableName: tableName,
		Limit: pageSize
	}, encryptItems.bind(null, tableName, encryptedProperties));
}

function encryptItems(tableName, encryptedProperties, items) {
	var promises = items.map(encryptItem.bind(null, encryptedProperties));

	Promise.all(promises)
		.then(encryptedItems => {
			var params = {
				RequestItems: {
					[tableName]: encryptedItems.map(item => ({ PutRequest: { Item: item } }))
				}
			};

			return dynamodbClient.batchWrite(params).promise();
		})
		.catch(err => console.log(err));

}

function encryptItem(encryptedProperties, item) {
	var keys = Object.keys(item);
	var encryptedItem = keys
		.filter(key => encryptedProperties.indexOf(key) < 0)
		.reduce((acc, key) => {
			acc[key] = item[key];
			return acc;
		}, {});
	var promises = keys
		.filter(key => encryptedProperties.indexOf(key) >= 0)
		.map(key => encrypt(item[key]).then(encrypted => ({ key: key, data: encrypted })));

	return Promise.all(promises)
		.then(encryptedProperties => {

			encryptedProperties
				.forEach(prop => encryptedItem[prop.key] = prop.data);

			return encryptedItem;
		})
		.catch(err => console.log(err));
}

function encrypt(data) {
	return encryptionPipeline.encrypt(config.encryption.dynamodb.keyId, data);
}
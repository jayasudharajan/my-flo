import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import { ValidationMixin, validateMethod } from '../../models/ValidationMixin';
import EncryptedDynamoTable from '../../models/EncryptedDynamoTable';
import TLocation from './models/TLocation';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import EncryptionStrategy from '../utils/EncryptionStrategy';

class LocationTable extends ValidationMixin(TLocation, EncryptedDynamoTable) {
	constructor(dynamoDbClient, encryptionStrategy) {
		const encryptedProperties = [
			'address',
			'address2',
			'city',
			'country',
			'location_type',
			'postalcode',
			'state',
			'timezone'
		];

		super('Location', 'account_id', 'location_id', encryptedProperties, dynamoDbClient, encryptionStrategy);
	}

	retrieveByAccountId(accountId) {
		const params = {
			TableName: this.tableName,
			KeyConditionExpression: 'account_id = :account_id',
			ExpressionAttributeValues: {
				':account_id': accountId
			}
		};

		return this.decryptQuery(this.dynamoDbClient.query(params).promise());
	}

	retrieveByLocationId(locationId) {
		const params = {
			TableName: this.tableName,
			IndexName: 'LocationIdIndex',
			KeyConditionExpression: 'location_id = :location_id',
			ExpressionAttributeValues: {
				':location_id': locationId
			}
		};

		return this.decryptQuery(this.dynamoDbClient.query(params).promise());
	}
}

validateMethod(
	LocationTable.prototype,
	'retrieveByAccountId',
	[tcustom.UUIDv4]
);

validateMethod(
	LocationTable.prototype,
	'retrieveByLocationId',
	[tcustom.UUIDv4]
);

export default DIFactory(LocationTable, [AWS.DynamoDB.DocumentClient, EncryptionStrategy]);
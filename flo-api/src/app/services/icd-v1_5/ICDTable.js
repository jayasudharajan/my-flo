import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import { ValidationMixin, validateMethod } from '../../models/ValidationMixin';
//import CachedDynamoTable from '../../models/cachedDynamoTable';
import DynamoTable from '../../models/DynamoTable';
import TICD from './models/TICD';
import AWS from 'aws-sdk';
import redis from 'redis';
import DIFactory from  '../../../util/DIFactory';

class ICDTable extends ValidationMixin(TICD, DynamoTable) {
	constructor(dynamoDbClient, redisClient) {
	    super('ICD', 'id', undefined, dynamoDbClient);
	}

	_retrieveCachedIndex(indexName, indexHashKey, dbQuery) {

    	// return this._withCache({
    	// 	key: cacheKey,
    	// 	fallback: () => dbQuery().then(result => result.Items.length ? result : null)
    	// });

    	return dbQuery();
	}

	_retrieveByLocationId(locationId) {
		const params = {
			TableName: this.tableName,
			IndexName: 'LocationIdIndex',
			KeyConditionExpression: 'location_id = :location_id',
			ExpressionAttributeValues: {
				':location_id': locationId
			}
		};

		return this.dynamoDbClient.query(params).promise();
	}

	retrieveByLocationId(locationId) {
		return this._retrieveCachedIndex('LocationIdIndex', locationId, () => this._retrieveByLocationId(locationId));
	}

	_retrieveByDeviceId(deviceId) {
		const params = {
			TableName: this.tableName,
			IndexName: 'DeviceIdIndex',
			KeyConditionExpression: 'device_id = :device_id',
			ExpressionAttributeValues: {
				':device_id': deviceId
			}
		};

		return this.dynamoDbClient.query(params).promise();
	}

	retrieveByDeviceId(deviceId) {
		return this._retrieveCachedIndex('DeviceIdIndex', deviceId, () => this._retrieveByDeviceId(deviceId));
	}

	remove(keys) {
		return this.dynamoDbClient.delete({
			TableName: this.tableName,
			Key: keys,
			ReturnValues: 'ALL_OLD'
		})
		.promise();
  }
}

validateMethod(
	ICDTable.prototype,
	'retrieveByLocationId',
	[tcustom.UUIDv4]
);

validateMethod(
	ICDTable.prototype,
	'retrieveByDeviceId',
	[tcustom.DeviceId]
);

export default new DIFactory(ICDTable, [AWS.DynamoDB.DocumentClient, redis.RedisClient]);
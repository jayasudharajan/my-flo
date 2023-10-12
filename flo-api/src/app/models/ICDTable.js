import _ from 'lodash';
import CachedDynamoTable from './cachedDynamoTable';
import AccountTable from './AccountTable';
import LocationTable from './LocationTable';
import ICDLogTable from './ICDLogTable';
import DIFactory from '../../util/DIFactory';
import AWS from 'aws-sdk';
import redis from 'redis';

const account = new AccountTable();
const location = new LocationTable();


class ICDTable extends CachedDynamoTable {

  constructor(dynamoDbClient, redisClient) {
    super('ICD', 'id', undefined, undefined, dynamoDbClient, redisClient);
  }

  /**
   * Retrieve an ICD based on location_id.  Uses a GSI.
   */
  _retrieveByLocationId(keys) {
    let indexName = "LocationIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: "location_id = :location_id",
      ExpressionAttributeValues: {
        ":location_id": keys.location_id
      }
    };

    return this.dynamoDbClient.query(params).promise();
  }

  retrieveByLocationId(keys) {
    const indexName = 'LocationIdIndex';
    const indexHashKey = 'location_id';
    const cacheKey = this._generateCacheKey(this.tableName + '_' + indexName, keys[indexHashKey]);

    return this._withCache({
      key: cacheKey,
      fallback: () => this._retrieveByLocationId(keys).then(({ Items }) => Items.length ? Items[0] : null)
    })
    .then(result => ({ Items: result ? [result] : [], Count: 1 }));
  }

  /**
   * Retrieve an ICD based on device_id.  Uses a GSI.
   */
  _retrieveByDeviceId(keys) {
    let indexName = "DeviceIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: "device_id = :device_id",
      ExpressionAttributeValues: {
        ":device_id": keys.device_id
      }
    };

    return this.dynamoDbClient.query(params).promise();
  }

  retrieveByDeviceId(keys) {
    const indexName = 'DeviceIdIndex';
    const indexHashKey = 'device_id';
    const cacheKey = this._generateCacheKey(this.tableName + '_' + indexName, keys[indexHashKey]);

    return this._withCache({
      key: cacheKey,
      fallback: () => this._retrieveByDeviceId(keys).then(({ Items }) => Items.length ? Items[0] : null)
    })
    .then(result => ({ Items: result ? [result] : [], Count: 1 }));
  }

  /**
   * Return a list of user ids related to a device_id.
   */
  retrieveUserIdsByDeviceId(keys) {
    // Get the location_id.
    // Get the account_id.
    // Return the owner_user_id.

    // TODO: Future - get info from UserRole.
    
    let location_id = "";
    let account_id = "";
    let user_id = "";
    
    // TODO: account for empty values.
    return this.retrieveByDeviceId(keys)
      .then(icdResult => {
        location_id = icdResult.Items[0].location_id;
        return location.retrieveByLocationId({ location_id });
      })
      .then(locationResult => {
        account_id = locationResult.Items[0].account_id;
        return account.retrieve({ id: account_id });
      })
      .then(accountResult => {
        let usersIds = [];
        if(accountResult.Item.owner_user_id) {
          usersIds.push(accountResult.Item.owner_user_id);
        }
        return new Promise((resolve, reject) => {
          resolve(usersIds);
        });
      })
      .catch(error => {
        return new Promise((resolve, reject) => {
          reject({ status: 404, message: 'Not found.' });
        });
      });
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

export default new DIFactory(ICDTable, [AWS.DynamoDB.DocumentClient, redis.RedisClient]);
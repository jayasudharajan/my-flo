import client from '../../util/dynamoUtil'; //, dynamo
import uuid from 'node-uuid';
import _ from 'lodash';
import config from '../../config/config';

/**
 * Base class that serves as a convenience wrapper for DynamoDB SDK actions.
 */
class DynamoTable {

  /**
   * tableName is mandatory, keyNames are optional.
   */
  constructor(tableName, keyName, rangeName, dynamoDbClient) {

    this.tableName = config.aws.dynamodb.prefix + tableName;
    // If no keyNames provided, defaults to 'id'.
    if(keyName) {
      this.keyName = keyName;
    } else {
      this.keyName = 'id';
    }
    // Check range key to set flag and key value.
    if(_.isUndefined(rangeName)) {
      this.haveRangeName = false;
    } else {
      this.rangeName = rangeName;
      this.haveRangeName = true;
    }

    this.dynamoDbClient = (typeof dynamoDbClient === 'undefined') ? client : dynamoDbClient;
  }

  _extractKeys(args) {
    const keys = _.isObject(args[0]) ?
      args[0] :
      { [this.keyName]: args[0], [this.rangeName]: args[1] };

    return _.omitBy(keys, _.isNil);
  }

  /**
   * Fetch one item.
   */
  retrieve(...args) {
    const keys = this._extractKeys(args);
    let params = {
      TableName: this.tableName,
      Key: keys
    };

    return this.dynamoDbClient.get(params).promise();
  }

  /**
   * Create an item.
   */
  create(rawData) {
    return this.marshal(rawData)
      .then(data => this._create(data));
  }

  _createCreateParams(params) {
    return params;
  }

  _create(data) {
    // Check range key, if exists in table.
    if(this.haveRangeName && (!data[this.keyName] && !data[this.rangeName])) {
      return new Promise((resolve, reject) => {
        reject({ message: 'Range key "' + this.rangeName + '" required.'})
      });
    }
    // Generates hashKeys and/or rangeKeys values for known keyNames if none exist.
    // Otherwise if keys are provided, is an implied update.
    if(!data[this.keyName]) {
      data[this.keyName] = uuid.v4();
    }
    if(this.haveRangeName && !data[this.rangeName]) {
      data[this.rangeName] = uuid.v4();
    }

    let params = this._createCreateParams({
      TableName: this.tableName,
      Item: data
    });

    return this.dynamoDbClient.put(params).promise()
      .then(result => {
        // NOTE: if empty, means was successful.
        // Return back the item with id.
        if(_.isEmpty(result)) {
          return new Promise((resolve, reject) => {
            resolve(data);
          });
        } else {
          return new Promise((resolve, reject) => {
            reject({ message: "Unable to create item."})
          });
        }

      });
  }

  /**
   * Update an item in it's entirety.  Requires that entity already exists.
   *
   * TODO: include keys in data or have separate like patch?
   */
  update(rawData) {
    return this.marshal(rawData)
      .then(data => this._update(data));
  }

  _createUpdateParams(params) {
    return params;
  }

  _update(data) {
    const rangeKeyExpression = this.rangeName ? ' AND attribute_exists(#range_key)' : '';
    const rangeKeyName = this.rangeName ? { '#range_key': this.rangeName } : {};
    const params = this._createUpdateParams({
      TableName: this.tableName,
      ConditionExpression: 'attribute_exists(#hash_key)' + rangeKeyExpression,
      ExpressionAttributeNames: {
        '#hash_key': this.keyName,
        ...rangeKeyName
      },
      Item: data
    });

    return this.dynamoDbClient.put(params).promise()
      .catch(err => {
        return Promise.reject(
          err.name === 'ConditionalCheckFailedException' ?
            { message: "Item not found."} :
            err
        );
      });
  }

  /**
   * Partial update of an item.
   */
  patch(keys, rawData, returnValues) {
    return _.isEmpty(rawData) ? 
      Promise.resolve({ Attributes: {} }) :
      this.marshalPatch(keys, rawData)
        .then(({ keys, data }) => this._patch(keys, data, returnValues));
  }

  _createPatchParams(params) {
    return params;
  }

  _patch(keys, data, returnValues) {
    const {
      UpdateExpression,
      ExpressionAttributeNames,
      ExpressionAttributeValues
    } = createUpdate(data);
    const params = this._createPatchParams({
      TableName: this.tableName,
      Key: keys,
      UpdateExpression,
      ExpressionAttributeNames,
      ExpressionAttributeValues,
      ReturnValues: returnValues || "UPDATED_NEW"
    });

    return this.dynamoDbClient.update(params).promise();
  }

  patchExisting(keys, rawData, returnValues) {
    return this.marshalPatch(keys, rawData)
      .then(({ keys, data }) => this._patchExisting(keys, data, returnValues))
  }

  _createPatchExistingParams(params) {
    return params;
  }

  _patchExisting(keys, data, returnValues) {
    const {
      UpdateExpression,
      ExpressionAttributeNames,
      ExpressionAttributeValues
    } = createUpdate(data);

    const params = this._createPatchExistingParams({
      TableName: this.tableName,
      ConditionExpression: 'attribute_exists(' + this.keyName + ')',
      Key: keys,
      UpdateExpression,
      ExpressionAttributeNames,
      ExpressionAttributeValues,
      ReturnValues: returnValues || "UPDATED_NEW"
    });

    return this.dynamoDbClient.update(params).promise();
  }

  /**
   * Delete one item.
   */
  remove(...args) {
    const keys = this._extractKeys(args);
    const params = {
      TableName: this.tableName,
      Key: keys
    };

    return this.dynamoDbClient.delete(params).promise();
  }

  /**
   * 'Delete' by setting an archive flag.
   */
  archive(...args) {
    const keys = this._extractKeys(args);
    const rangeKeyExpression = this.rangeName ? ' AND attribute_exists(#range_key)' : '';
    const rangeKeyName = this.rangeName ? { '#range_key': this.rangeName } : {};
    const params = {
      TableName: this.tableName,
      Key: keys,
      ConditionExpression: 'attribute_exists(#hash_key)' + rangeKeyExpression,
      UpdateExpression: "SET is_deleted = :is_deleted",
      ExpressionAttributeNames: {
        '#hash_key': this.keyName,
        ...rangeKeyName
      },
      ExpressionAttributeValues: {
        ':is_deleted': true 
      },
      ReturnValues: 'UPDATED_NEW'
    };

    return this.dynamoDbClient.update(params).promise()
      .catch(err => {
        return Promise.reject(
          err.name === 'ConditionalCheckFailedException' ?
            { message: "Item not found."} :
            err
        );
      });
  }

  /**
   * NOTE: scan functions below are for development and testing only and will be
   * removed once query and indices approach is resolved.
   */

  scanAll(limit, keys) {

    let params = {
      TableName: this.tableName
    };
    if(!_.isUndefined(limit)) params.Limit = limit;
    if(!_.isUndefined(keys) && !_.isEmpty(keys)) params.ExclusiveStartKey = keys;

    return this.dynamoDbClient.scan(params).promise();
  }

  scanActive() {

    let filter_expression = "attribute_not_exists(is_deleted) OR NOT (is_deleted = :is_deleted)";

    let params = {
      TableName: this.tableName,
      FilterExpression: filter_expression,
      ExpressionAttributeValues: {
          ":is_deleted": true
      }
    };

    return this.dynamoDbClient.scan(params).promise();
  }

  
  _query(params) {
    return this.dynamoDbClient.query(params).promise();
  }

  _exhaustiveQuery(params, results = []) {
    return this._query(params)
      .then(result => {

        if (result.LastEvaluatedKey) {
          return this._exhaustiveQuery(
            { 
              ...params, 
              ExclusiveStartKey: result.LastEvaluatedKey 
            }, 
            results.concat([result])
          );
        } else {
          return results.concat([result])
            .reduce(
              (acc, result) => ({
                ...result,
                ...acc,
                Items: (acc.Items || []).concat(result.Items || []),
                Count: (acc.Count || 0) + (result.Count || 0)
              }), 
              {}
            );
        }
      });
  }

  _withExhaustivePaging(operation, exclusiveStartKey, results = []) {
    return operation(exclusiveStartKey)
      .then(result => {
        if (result.LastEvaluatedKey) {
          return this._withExhaustivePaging(operation, result.LastEvaluatedKey, [...results, result]);
        } 

        return [...results, result]
          .reduce(
            (acc, result) => ({
              ...result,
              ...acc,
              Items: [...(acc.Items || []), ...(result.Items || [])],
              Count: (acc.Count || 0) + (result.Count || 0)
            }),
            {}
          );      
      });
  }

  marshal(data) {
    return Promise.resolve(mapEmptyToNull(data));
  }

  marshalPatch(keys, data) {
    return Promise.resolve({
      keys,
      data: _.omit(data, Object.keys(keys))
    });
  }

  batchCreate(records = [], attempts) {
    const putRequestPromises = records
      .map(record => 
        this.marshal(record)
          .then(marshaledRecord => ({ 
            PutRequest: {
              Item: marshaledRecord 
            }
          }))
      );

    return Promise.all(putRequestPromises)
      .then(putRequests => 
        this._batchCreate(putRequests, attempts)
      );
  }

  _batchCreate(putRequests, remainingAttempts = 3) {
    return this.dynamoDbClient.batchWrite({
      RequestItems: {
        [this.tableName]: putRequests
      }
    })
    .promise()
    .then(({ UnprocessedItems }) => {
      const unprocessedPutRequests = UnprocessedItems && UnprocessedItems[this.tableName];

      if (unprocessedPutRequests && remainingAttempts > 0) {
        return this._batchCreate(unprocessedPutRequests, remainingAttempts - 1);
      } else if (unprocessedPutRequests) {
        return Promise.reject(new Error('Unable to process whole batch.'));
      }

    });
  }
}

function mapEmptyToNull(obj, visited = []) {
  return  _[Array.isArray(obj) ? 'map' : 'mapValues'](obj, val => {
    const isObject = _.isObject(val);
    
    if (isObject && visited.indexOf(val) >= 0) {
      throw 'Cannot write object with circular properties.'
    } else if (isObject) {
      return mapEmptyToNull(val, [...visited, val]);
    } else if (val === '' || val === undefined) {
      return null;
    } else {
      return val;
    }
  });
}

function createUpdate(data) {
  let update_expression = '';
  let update_expression_update = "SET";
  let update_expression_remove = "REMOVE";
  let expression_attribute_names = {};
  let attribute_values = {};

  // Create update expression and values.
  for(let data_key in data) {
    // Account for reserved words conflicts using aliases.
    if(data[data_key] === '') {
      update_expression_remove += " #" + data_key + ",";
    } else {
      update_expression_update += " #" + data_key + " = :" + data_key + ",";
      attribute_values[":" + data_key]= data[data_key];
    }
    expression_attribute_names["#" + data_key] = data_key;
  }
  // removes comma and combine update & remove
  if(update_expression_update !== 'SET') update_expression = update_expression_update.substr(0, update_expression_update.length - 1);
  if(update_expression_remove !== 'REMOVE') {
    if(update_expression !== '') update_expression += ' ';
    update_expression += update_expression_remove.substr(0, update_expression_remove.length - 1);
  }

  return {
    UpdateExpression: update_expression,
    ExpressionAttributeNames: expression_attribute_names,
    ExpressionAttributeValues: attribute_values
  };
}


export default DynamoTable;
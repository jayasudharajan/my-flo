"use strict";

var glob = require('glob');
var AWS = require('aws-sdk');
var chalk = require('chalk');
var config = require('../src/config/config');
var sleep = require('sleep');
var jsonfile = require('jsonfile');
var _ = require('lodash');

// Config.
AWS.config.update({
  accessKeyId: config.aws.accessKeyId,
  secretAccessKey: config.aws.secretAccessKey,
  region: config.aws.dynamodb.region,
  endpoint: config.aws.dynamodb.endpoint,
  apiVersion: config.aws.apiVersion
});

let client = new AWS.DynamoDB.DocumentClient();
let dynamo = new AWS.DynamoDB();
let prefix = config.aws.dynamodb.prefix;
let promises = [];

jsonfile.spaces = 2;
let exportDir = config.root + config.initData;
let batchLimit = 25;

let currentBatch = 0;

// Gather data from a list of tables.
let tableList = ["AccountGroup", "FAQiOS", "FAQAndroid", "ICDAlarmNotificationDeliveryRule", "KernelVersion", "TimeZone", "UltimaVersion"];
//let tableList = ["AccountGroup"];
for(let table of tableList) {
  promises.push(batchWrite(prefix + table, require(exportDir + table + '.json')));
}

// Run.
Promise.all(promises)
  .then(values => {
    console.log(values)
    // TODO: Show Unprocessed items.
    // TODO: Show friendly message.
  })
  .catch((err) => {
    console.log(err);
  });

// TODO: Chunk batches of 25 records max.
// function createBatches(tableName, data) {
//   if(currentBatch < batchLimit) {
//     promises.push(batchWrite(prefix + table, require(exportDir + table + '.json')));
//     currentBatch = currentBatch + 1;
//     console.log(currentBatch)
//   } else {
//     break;
//   }
// }

// Batch write data.
function batchWrite(tableName, data) {
  // TEMP - just get first 25.
  data = _.slice(data, 0, 25)

  let params = createBatchParams(tableName, data);
  console.log(params);
  return client.batchWrite(params).promise()
    .then(data =>
      new Promise((resolve, reject) => resolve(data))
    );
}

function createBatchParams(tableName, data) {
  let params = {
    RequestItems: {
      [tableName]: []
    },
    ReturnConsumedCapacity: 'TOTAL',
    ReturnItemCollectionMetrics: 'SIZE'
  };
  for(let item of data) {
    params.RequestItems[tableName].push(createPutRequest(item))
  }
  return params;
}

function createPutRequest(item) {
  let request = { "PutRequest": { "Item": {} } };

  // NOTE: tested with multiple types: string, boolean, numeric, array, map, null.
  for(let field in item) {
    request.PutRequest.Item[field] = item[field];
  }
  return request;
}

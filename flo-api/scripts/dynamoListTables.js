"use strict";

var glob = require('glob');
var AWS = require('aws-sdk');
var chalk = require('chalk');
var config = require('../src/config/config');
var sleep = require('sleep');
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

// List current tables for a 'prefix'.
// dynamo.listTables({}, (err, data) => {
//   let tables = data.TableNames;
//   tables.forEach((table) => {
//     if(_.startsWith(table, config.aws.dynamodb.prefix)) {
//       console.log(table);
//     }
//   });
// });

// List all tables.
dynamo.listTables({}, (err, data) => {
  let tables = data.TableNames;
  tables.forEach((table) => {
    console.log(table);
  });
});

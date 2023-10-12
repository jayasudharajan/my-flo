"use strict";

var glob = require('glob');
var AWS = require('aws-sdk');
var chalk = require('chalk');
var config = require('../src/config/config');
var sleep = require('sleep');

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

function deleteTable(tableName, prefix) {
  var params = {
    TableName: prefix + tableName
  };
  dynamo.deleteTable(params, (err, data) => {
    if (err) {
      console.log(JSON.stringify(err, null, 2));
    } else {
      console.log(params.TableName + " table destroyed.");
      //console.log(JSON.stringify(data, null, 2));

      // sleep (in microseconds)
      sleep.usleep(500000);
    }
  });
}

// Retrieve all Table schemas.
// DELETE ALL tables.
// NOTE: comment this out to prevent uwanted delete.
// dynamo.listTables({}, (err, data) => {
//   let tables = data.TableNames;
//   tables.forEach((table) => {
//     deleteTable(table, '');  //config.aws.dynamodb.prefix  //"dev_"
//   });
// });

// DELETE specific tables.
// let tableList = ["AccountGroup"];
// for(let table of tableList) {
//   deleteTable(table, config.aws.dynamodb.prefix);
// }

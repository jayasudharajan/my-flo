"use strict";

var glob = require('glob');
var AWS = require('aws-sdk');
var chalk = require('chalk');
var config = require('../src/config/config');
var sleep = require('sleep');

// Config.
AWS.config.update({
  region: config.aws.dynamodb.region
});

let client = new AWS.DynamoDB.DocumentClient();
let dynamo = new AWS.DynamoDB();

function createTable(params, prefix) {

  params.TableName = prefix + params.TableName;

  dynamo.createTable(params, (err, data) => {
    if (err) {
      switch (err.code) {
        case 'ResourceInUseException':
          console.log(params.TableName + " already exists.");
          break;
        default:
          console.log(JSON.stringify(err, null, 2));
      }

    } else {

      console.log(chalk.green(params.TableName + " table created."));

      // sleep (in microseconds)
      sleep.usleep(500000);
    }
  });
}

// Retrieve all Table schemas.
let tables = glob.sync(config.root + '/app/models/schemas/*.js');

// CREATE all tables in /models/schemas.
tables.forEach((table) => {
  createTable(require(table), config.aws.dynamodb.prefix);
});

// CREATE ONE table.
// createTable(require(config.root + '/app/models/schemas/timeZoneSchema.js'), config.aws.dynamodb.prefix);

// List current tables.
// TODO: list by prefix.
// dynamo.listTables({}, (err, data) => {
//   let tables = data.TableNames;
//   tables.forEach((table) => {
//     console.log(table)
//   });
// });

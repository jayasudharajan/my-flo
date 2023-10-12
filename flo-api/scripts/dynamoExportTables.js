"use strict";

var glob = require('glob');
var AWS = require('aws-sdk');
var chalk = require('chalk');
var config = require('../src/config/config');
var sleep = require('sleep');
var fs = require('fs');
var jsonfile = require('jsonfile')

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
let scanLimit = 500;

// Get a list of tables to export.
let tableList = ["AccountGroup", "FAQiOS", "FAQAndroid", "ICDAlarmNotificationDeliveryRule", "KernelVersion", "TimeZone", "UltimaVersion"];
//let tableList = ["AccountGroup"];
for(let table of tableList) {
  promises.push(getTableData(prefix + table, scanLimit));
}

console.log();
console.log(chalk.yellow('Exporting from ' + config.aws.dynamodb.endpoint));

// Scan data for each table and export as JSON.
Promise.all(promises)
  .then(values => {

    for(let i in values) {
      
      let filename = exportDir + tableList[i] + '.json';
      //console.log(values[i])
      //console.log(filename)

      if(values[i].Count > 0) {
        jsonfile.writeFile(filename, values[i].Items, (err) => {
          if (err) {
            //console.log(err)
            return new Promise((resolve, reject) => reject(err));
          } else {
            console.log('Saving - ' + chalk.green(tableList[i] + '.json') + ' - ' + values[i].Count + ' record(s).');
          }
        });
      } else {
        console.log('0 records found for ' + chalk.red(tableList[i] + '.'));
      }

    }

  })
  .catch((err) => {
    console.log(err);
  });

// Scan a table and return Items.
function getTableData(tableName, limit) {
  if(!limit) limit=0;
  var params = {
    TableName: tableName,
    Limit: limit
  };
  return client.scan(params).promise()
    .then(data =>
      new Promise((resolve, reject) =>
        resolve(data)
      )
    );
}

// data.Items.map(item => item.role_def

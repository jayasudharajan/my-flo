var AWS = require('aws-sdk');
var config = require('../config/config');

// Config AWS.
const cfg = {
  region: config.aws.dynamodb.region,
  endpoint: config.aws.dynamodb.endpoint,
  apiVersion: config.aws.apiVersion,
  httpOptions: {
    timeout: config.aws.timeoutMs
  }
};

// TODO: fix this to support more than default and leverage ES6.
//export client = return new AWS.DynamoDB.DocumentClient();

let client = new AWS.DynamoDB.DocumentClient(cfg);
export default client;

export function dynamo() {
  return new AWS.DynamoDB(cfg);
}
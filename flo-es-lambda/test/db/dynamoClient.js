const aws = require('aws-sdk');
const config = require('../config');

module.exports = new aws.DynamoDB.DocumentClient(config.dynamo);
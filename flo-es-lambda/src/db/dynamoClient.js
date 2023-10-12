const AWS = require('aws-sdk');
const config = require('../config');
const decrypt = require('../util/decrypt');
const _ = require('lodash');

const dynamoClient = new AWS.DynamoDB.DocumentClient(config.dynamo);
const _get = dynamoClient.get.bind(dynamoClient);
const _query = dynamoClient.query.bind(dynamoClient);
const cachedReads = [];

module.exports = Object.assign(
  dynamoClient,
  { 
    get: cacheRead(get),  
    query: cacheRead(query)
  }
);

function cacheRead(fn) {
  return args => {
    const cachedResult = _.find(cachedReads, ({ query }) => _.isEqual(query, args));
    const result = cachedResult ? cachedResult.result : fn(args);

    if (!cachedResult) {
      cachedReads.push({ query: args, result });
    }

    return result; 
  };
}

function get(args) {
  const dynamoQuery = _get(args);
  const promise = dynamoQuery
    .promise()
    .then(result => 
      decrypt(args.TableName, result.Item)
        .then(decryptedItem => 
          Object.assign(result, { Item: decryptedItem })
        )
    );

  return Object.assign(dynamoQuery, { promise: () => promise });
}


function query(args) {
  const dynamoQuery = _query(args);
  const promise = dynamoQuery
    .promise()
    .then(result => 
      Promise.all(
        result.Items.map(item => decrypt(args.TableName, item))
      )
      .then(decryptedItems => 
        Object.assign(result, { Items: decryptedItems })
      )
    );

  return Object.assign(dynamoQuery, { promise: () => promise });      
}
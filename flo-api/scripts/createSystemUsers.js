"use strict";

const _ = require('lodash');
const AWS = require('aws-sdk');
const bcrypt = require('bcrypt');
const uuid = require('node-uuid');
const crypto = require('crypto');
const systemUsers = require('./systemUsers.json');

const tablePrefix = process.env.FLO_API_AWS_DYNAMODB_PREFIX;

AWS.config.update({
  accessKeyId: process.env.FLO_API_AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.FLO_API_AWS_SECRET_ACCESS_KEY,
  region: process.env.FLO_API_AWS_DYNAMODB_REGION,
  endpoint: process.env.FLO_API_AWS_DYNAMODB_ENDPOINT,
  apiVersion: process.env.FLO_API_AWS_API_VERSION
});

const dynamoClient = new AWS.DynamoDB.DocumentClient();

// WARNING: Due to issue importing ES6 modules in gulp tasks, code has been
// replicated from other files. 
// TODO: Find a way to share code across these modules rather than 
// copy & pasting

// REPLICATED FROM: util/encryption
function hashPassword(password) {
  const salt = createSalt();
  return hashPwd(salt, password);
}

function createSalt() {
  return bcrypt.genSaltSync(10);
}

function hashPwd(salt, pwd) {
  return bcrypt.hashSync(pwd, salt);
}

function verifyPassword(password, hashedPassword) {
  return bcrypt.compareSync(password, hashedPassword);
}

// REPLICATED (& EDITED) FROM: models/UserTable
function createUser(data) {    
  const tableName = `${tablePrefix}User`;
  const hashedEmail = hmac(data.email);
  const queryParams = {
    TableName: tableName,
    IndexName: "UserEmail",
    KeyConditionExpression: "email_hash = :email_hash",
    ExpressionAttributeValues: { 
      ":email_hash": hashedEmail
    },
    "ProjectionExpression": "id"
  };

  return dynamoClient
    .query(queryParams)
    .promise()
    .then(results => {
      const hashedPassword = data.password && hashPassword(data.password);
      const user = _.extend(data, {
        id: results.Count ? results.Items[0].id : uuid.v4(),
        email_hash: hashedEmail,
        password: hashedPassword
      });

      const putParams = {
        TableName: tableName,
        Item: user
      };
      
      console.log(putParams);

      return dynamoClient
        .put(putParams)
        .promise()
        .then(() => user);
    });
}

function createUserSystemRole(userId) {
  const params = {
    TableName: `${tablePrefix}UserSystemRole`,
    Item: {
      user_id: userId,
      roles: [ 'admin' ]
    }
  };
  return dynamoClient.put(params).promise();
}

function hmac(data) {
  const hmac = crypto.createHmac('sha256', Buffer(process.env.FLO_API_HMAC_KEY, 'base64'));
  return hmac
    .update(data)
    .digest('hex');
}

const promises = (systemUsers || [])
  .map(data => 
    createUser({
      email: data.email,
      password: data.password,
      is_active: true,
      is_system_user: true
    })
    .then(user => 
      createUserSystemRole(user.id)
      .then(() => user)
    )
  );


(() => 
  Promise.all(promises)
    .then(results => {
      results.forEach(results => 
        console.log(JSON.stringify({ 
          id: results.id,
          email: results.email,
        }))
      );
    })
    .catch(err => {
  	  console.log(err);
      process.exit(1);
    })
)();
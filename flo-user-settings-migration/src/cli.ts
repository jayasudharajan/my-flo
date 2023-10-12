#!/usr/bin/env node
import UserAlarmSettingsMigrationService from  './UserAlarmSettingsMigrationService';
import APIV1Service from './APIV1Service';
import GatewayService from './GatewayService';
import config from './config';
import axios from 'axios';
import AWS, { DynamoDB } from 'aws-sdk';
import DynamoDbClient from './database/dynamo/DynamoDbClient';
import moment from 'moment-timezone';

axios.defaults.headers.common['Authorization'] = config.apiToken;

AWS.config.update({
  region: config.awsRegion
});

const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const migrationService = new UserAlarmSettingsMigrationService(new APIV1Service(), new GatewayService());

console.log(`Migration started at ${moment().toISOString()}`);

dynamoDbClient.scan('User', (user: any) =>
  migrationService
    .migrate(user.id)
    .catch(e => console.log(e))
);

console.log(`Migration finished at ${moment().toISOString()}`);



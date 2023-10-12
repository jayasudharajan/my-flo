import { Callback, Context, DynamoDBStreamEvent, DynamoDBStreamHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import Delighted from 'delighted';
import _ from 'lodash';
import config from './config';
import DbHelper from './DbHelper';
import DelightedApi from './DelightedApi';
import DynamoDbClient from './DynamoDbClient';
import AccountSubscriptionEventHandler from './handler/AccountSubscriptionHandler';
import OnboardingLogEventHandler from './handler/OnboardingLogEventHandler';
import { AccountSubscription, OnboardingLog } from './interfaces';

const delightedClient = Delighted(config.delightedApiKey);
const dynamoDb = new DynamoDB.DocumentClient();
const dynamoDbClient = new DynamoDbClient(dynamoDb, config.tablePrefix);
const dbHelper = new DbHelper(dynamoDbClient);
const delightedApi = new DelightedApi(delightedClient);
const onboardingLogHandler = new OnboardingLogEventHandler(delightedApi, dbHelper);
const accountSubscriptionHandler = new AccountSubscriptionEventHandler(delightedApi, dbHelper);

const parseTableName = (eventSourceArn?: string): string | null => {
  if (_.isNil(eventSourceArn)) {
    return null;
  }
  return eventSourceArn.split(':')[5].split('/')[1];
}

const isSubscriptionEvent = (tableName: string): boolean => tableName === `${config.tablePrefix}AccountSubscription`;

const isOnboardingLogEvent = (tableName: string): boolean => tableName === `${config.tablePrefix}OnboardingLog`;

export const sendToDelighted: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent, _context: Context, done: Callback<void>) => {

  const newRecords = event.Records
    .filter(record => record.eventName === 'INSERT')
    .map(record => {
      const newImageOrEmpty = (record.dynamodb && record.dynamodb.NewImage) || {};
      return {
        data: DynamoDB.Converter.unmarshall(newImageOrEmpty),
        table: parseTableName(record.eventSourceARN)
      }
    });

  await Promise.all(newRecords.map(record => {
    if (_.isNil(record.table)) {
      console.warn('Could not parse table name. Skipping event.')
      return Promise.resolve();
    }

    if (isSubscriptionEvent(record.table)) {
      const subscription = record.data as AccountSubscription;
      console.log(`Processing Subscription event for Account ID ${subscription.account_id}`);
      return accountSubscriptionHandler.handle(subscription);
    }

    if (isOnboardingLogEvent(record.table)) {
      console.log(`Processing OnboardingLog event => ${JSON.stringify(record.data)}`);
      const log = record.data as OnboardingLog;
      return onboardingLogHandler.handle(log);
    }

    return Promise.resolve();
  }));

  done();
}

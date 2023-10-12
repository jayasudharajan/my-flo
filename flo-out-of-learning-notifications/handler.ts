import { Callback, Context, DynamoDBStreamEvent, DynamoDBStreamHandler } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import 'source-map-support/register';
import { OnboardingLog } from './interfaces';
import sendEventToPinpoint from './index';

export const sendEventsToPinpoint: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent, _context: Context, done: Callback<void>) => {
  const newRecords = event.Records.map(record => {
    const newImageOrEmpty = (record.dynamodb && record.dynamodb.NewImage) || {};
    return DynamoDB.Converter.unmarshall(newImageOrEmpty);
  });

  await Promise.all(newRecords.map(async (record) => {
    const log = record as OnboardingLog
    return sendEventToPinpoint(log);
  }));

  done();
}

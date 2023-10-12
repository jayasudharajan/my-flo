import { DynamoDBStreamEvent } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import { OnboardingLog } from '../interfaces';
import { handleOnboardingLog } from './onboardingLogHandler';

export const handleEvent = async (event: DynamoDBStreamEvent): Promise<void> => {
  const newRecords = event.Records.map(record => {
    const newImageOrEmpty = (record.dynamodb && record.dynamodb.NewImage) || {};
    return DynamoDB.Converter.unmarshall(newImageOrEmpty);
  });

  await Promise.all(newRecords.map(async (record) =>
    handleOnboardingLog(record as OnboardingLog)
  ));
};
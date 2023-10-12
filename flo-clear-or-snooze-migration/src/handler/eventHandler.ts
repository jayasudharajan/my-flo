import { DynamoDBStreamEvent } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import { handleICDAlarmIncidentRegistry } from './icdAlarmIncidentRegistry';

export const handleEvent = async (event: DynamoDBStreamEvent): Promise<void> => {
  const newRecords = event.Records
    .map(record => {
      const oldImageOrEmpty = (record.dynamodb && record.dynamodb.OldImage) || {};
      const newImageOrEmpty = (record.dynamodb && record.dynamodb.NewImage) || {};

      return {
        old: DynamoDB.Converter.unmarshall(oldImageOrEmpty),
        'new': DynamoDB.Converter.unmarshall(newImageOrEmpty)
      };
    });

  await Promise.all(newRecords.map(async (record) =>
    handleICDAlarmIncidentRegistry(record)
  ));
};

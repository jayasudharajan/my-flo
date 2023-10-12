import _ from 'lodash';
import { DynamoDBStreamEvent } from 'aws-lambda';
import { DynamoDB } from 'aws-sdk';
import { RecordImage } from '../interfaces';

export const handleEvent = async <T>(event: DynamoDBStreamEvent, handler: (record: RecordImage<T>) => Promise<void>): Promise<void> => {
  const newRecords = event.Records
    .map(record => {
      const newImageOrEmpty = (record.dynamodb && record.dynamodb.NewImage) || {};
      const oldImageOrEmpty = (record.dynamodb && record.dynamodb.OldImage) || {};
      return record.eventName !== 'REMOVE' && !_.isEmpty(newImageOrEmpty) ? {
        old: DynamoDB.Converter.unmarshall(oldImageOrEmpty),
        new: DynamoDB.Converter.unmarshall(newImageOrEmpty)
      } : {};
    }
    ).filter(r => !_.isEmpty(r));

  await Promise.all(newRecords.map(async (record) =>
    handler(record as RecordImage<T>)
  ));
};
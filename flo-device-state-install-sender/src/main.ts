import { Callback, Context, DynamoDBStreamEvent, DynamoDBStreamHandler } from 'aws-lambda';
import { handleEvent } from './handler/eventHandler';

export const handle: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent, _context: Context, done: Callback<void>) => {
  await handleEvent(event);
  done();
};
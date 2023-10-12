import { Callback, Context, DynamoDBStreamEvent, DynamoDBStreamHandler } from 'aws-lambda';
import { handleEvent } from './handler/eventHandler';

export const handle: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent, _context: Context, done: Callback<void>) => {
  try {
    await handleEvent(event);
    done();
  } catch (err) {
    console.log(err);
    done(err);
  }
};
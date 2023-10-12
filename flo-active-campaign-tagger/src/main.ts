import { Callback, Context, DynamoDBStreamEvent, DynamoDBStreamHandler } from 'aws-lambda';
import { handleEvent } from './handler/eventHandler';
import { handleOnboardingLog } from './handler/onboardingLogHandler';
import { OnboardingLog } from './interfaces';

export const handle: DynamoDBStreamHandler = async (event: DynamoDBStreamEvent, _context: Context, done: Callback<void>) => {
  await handleEvent<OnboardingLog>(event, handleOnboardingLog);
  done();
};
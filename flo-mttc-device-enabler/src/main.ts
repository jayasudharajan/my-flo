import { Callback, Context, ScheduledEvent, ScheduledHandler } from 'aws-lambda';
import { handleEvent } from './handler/eventHandler';

export const handle: ScheduledHandler = async (event: ScheduledEvent, _context: Context, done: Callback<void>) => {
  await handleEvent(event);
  done();
};
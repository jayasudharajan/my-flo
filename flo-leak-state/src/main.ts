import { Callback, Context, ScheduledEvent, ScheduledHandler } from 'aws-lambda';
import { handleEvent } from './handler/eventHandler';

export const handle: ScheduledHandler = async (_event: ScheduledEvent, _context: Context, _done: Callback<void>) => {
  await handleEvent();
};
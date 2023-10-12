import { ContainerModule } from 'inversify';
import PushNotificationTokenTable from './PushNotificationTokenTable';
import PushNotificationTokenService from './PushNotificationTokenService';
import PushNotificationTokenController from './PushNotificationTokenController';
import PushNotificationTokenRouter from './routes';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule(bind => {
  bind(PushNotificationTokenTable).to(PushNotificationTokenTable);
  bind(PushNotificationTokenService).to(PushNotificationTokenService);
  bind(PushNotificationTokenController).to(PushNotificationTokenController);
  bind(PushNotificationTokenRouter).to(PushNotificationTokenRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/pushnotificationtokens', container => container.get(PushNotificationTokenRouter).router));
});
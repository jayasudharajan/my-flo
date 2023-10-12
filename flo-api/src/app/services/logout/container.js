import { ContainerModule } from 'inversify';
import RouterDIFactory from '../../../util/RouterDIFactory';
import LogoutService from './LogoutService';
import LogoutController from './LogoutController';
import LogoutRouter from './routes';

export const containerModule = new ContainerModule(bind => {
  bind(LogoutService).to(LogoutService);
  bind(LogoutController).to(LogoutController);
  bind(LogoutRouter).to(LogoutRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/logout', container => container.get(LogoutRouter).router));
});
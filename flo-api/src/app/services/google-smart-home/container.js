import axios from 'axios';
import Influx from 'influx';
import { ContainerModule } from 'inversify';
import config from '../../../config/config';
import RouterDIFactory from '../../../util/RouterDIFactory';
import AlertsService from '../alerts/AlertsService';
import InfoService from '../info/InfoService';
import GoogleSmartHomeController from './GoogleSmartHomeController';
import GoogleSmartHomeService from './GoogleSmartHomeService';
import GoogleSmartHomeRouter from './routes';

export const containerModule = new ContainerModule((bind, unbound, isBound) => {
  bind(GoogleSmartHomeService).to(GoogleSmartHomeService);
  bind(GoogleSmartHomeController).to(GoogleSmartHomeController);
  bind(GoogleSmartHomeRouter).to(GoogleSmartHomeRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/google', container => container.get(GoogleSmartHomeRouter).router));
  if (!isBound(InfoService)) {
    bind(InfoService).to(InfoService);
  }
  if (!isBound(AlertsService)) {
    bind(AlertsService).to(AlertsService)
  }

  if (!isBound('GoogleSmartHomeConfig')) {
    bind('GoogleSmartHomeConfig').toConstantValue(config);
  }

  if (!isBound('HttpClient')) {
    bind('HttpClient').toConstantValue(axios);
  }
});

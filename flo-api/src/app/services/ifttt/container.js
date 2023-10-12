import TriggerIdentityTable from './TriggerIdentityLogTable';
import IFTTTService from './IFTTTService';
import IFTTTController from './IFTTTController';
import IFTTTRouter from './routes';
import IFTTTTestService from './IFTTTTestService';
import { Container, ContainerModule } from 'inversify';
import InfoService from '../info/InfoService';
import AlertsService from '../alerts/AlertsService';
import OAuth2Service from '../oauth2/OAuth2Service';
import RouterDIFactory from '../../../util/RouterDIFactory';
import config from '../../../config/config';
import axios from 'axios';

const container = new Container();

export const containerModule = new ContainerModule((bind, unbound, isBound) => {
  
  if (!isBound(InfoService)) {
    bind(InfoService).to(InfoService);
  }

  if (!isBound(AlertsService)) {
    bind(AlertsService).toConstantValue(new AlertsService());
  }

  if (!isBound(OAuth2Service)) {
    bind(OAuth2Service).to(OAuth2Service);
  }

  bind(TriggerIdentityTable).to(TriggerIdentityTable);
  bind(IFTTTService).to(IFTTTService);
  bind(IFTTTController).to(IFTTTController);
  bind(IFTTTRouter).to(IFTTTRouter);
  bind(IFTTTTestService).to(IFTTTTestService);
  bind('IFTTTConfig').toConstantValue(config);

  bind('IFTTTServiceFactoryFactory').toFactory(context => 
    isTest => isTest ? context.container.get(IFTTTTestService) : context.container.get(IFTTTService)
  );

  if (!isBound('HttpClient')) {
    bind('HttpClient').toConstantValue(axios);
  }

  bind('RouterFactory')
    .toConstantValue(new RouterDIFactory('/api/v1/ifttt/v1', container => container.get(IFTTTRouter).router));
});


export default container;
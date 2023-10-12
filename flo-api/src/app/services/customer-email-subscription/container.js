import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import containerUtil from '../../../util/containerUtil';
import CustomerEmailSubscriptionTable from './CustomerEmailSubscriptionTable';
import CustomerEmailTable from './CustomerEmailTable';
import CustomerEmailSubscriptionService from './CustomerEmailSubscriptionService';
import CustomerEmailSubscriptionController from './CustomerEmailSubscriptionController';
import CustomerEmailSubscriptionRouter from './routes';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule(bind => {
  bind(CustomerEmailSubscriptionTable).to(CustomerEmailSubscriptionTable);
  bind(CustomerEmailTable).to(CustomerEmailTable);
  bind(CustomerEmailSubscriptionService).to(CustomerEmailSubscriptionService);
  bind(CustomerEmailSubscriptionController).to(CustomerEmailSubscriptionController);
  bind(CustomerEmailSubscriptionRouter).to(CustomerEmailSubscriptionRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/customeremail', container => container.get(CustomerEmailSubscriptionRouter).router));
});

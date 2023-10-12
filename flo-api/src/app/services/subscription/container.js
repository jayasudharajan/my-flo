import config from '../../../config/config'
import reflect from 'reflect-metadata';
import { Container } from 'inversify';
import StripeClient from 'stripe';
import AuthMiddleware from '../utils/AuthMiddleware';
import StripeWebhookAuthMiddleware from './StripeWebhookAuthMiddleware';
import SubscriptionController from './SubscriptionController';
import SubscriptionRouter from './routes';
import SubscriptionConfig from './SubscriptionConfig';
import SubscriptionService from './SubscriptionService';
import AccountSubscriptionTable from './AccountSubscriptionTable';
import SubscriptionPlanTable from './SubscriptionPlanTable';
import containerUtil from '../../../util/containerUtil';
import userAccountContainer from '../user-account/container';
import accountContainer from '../account-v1_5/container';
import authorizationContainer from '../authorization/container';
import locationContainer from '../location-v1_5/container';

const container = new Container();

container.bind(StripeClient).toConstantValue(StripeClient(config.stripeSecretKey));
container.bind(AuthMiddleware).to(AuthMiddleware).whenTargetIsDefault();
container.bind(AuthMiddleware).to(StripeWebhookAuthMiddleware).whenTargetNamed('StripeWebhook');
container.bind(SubscriptionController).to(SubscriptionController);
container.bind(SubscriptionRouter).to(SubscriptionRouter);
container.bind(SubscriptionConfig).toConstantValue(new SubscriptionConfig(config));
container.bind(SubscriptionService).to(SubscriptionService);
container.bind(AccountSubscriptionTable).to(AccountSubscriptionTable);
container.bind(SubscriptionPlanTable).to(SubscriptionPlanTable);

export default [
  userAccountContainer,
  accountContainer,
  authorizationContainer,
  locationContainer
].reduce(containerUtil.mergeContainers, container);
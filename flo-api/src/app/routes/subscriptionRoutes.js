import SubscriptionRouter from '../services/subscription/routes';
import subscriptionContainer from '../services/subscription/container';
import containerUtils from '../../util/containerUtil';

export default (app, appContainer) => {
  const container = containerUtils.mergeContainers(appContainer, subscriptionContainer);

  app.use('/api/v1/subscriptions', container.get(SubscriptionRouter).router);
}
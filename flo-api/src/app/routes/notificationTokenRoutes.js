import notificationTokenContainer from '../services/notification-token/container';
import NotificationTokenRouter from '../services/notification-token/routes';
import containerUtils from '../../util/containerUtil';

export default (app, appContainer) => {
  const container = containerUtils.mergeContainers(appContainer, notificationTokenContainer);

  app.use('/api/v1/notificationtokens', container.get(NotificationTokenRouter).router);  
}
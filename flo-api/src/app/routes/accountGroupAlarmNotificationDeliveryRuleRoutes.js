import AccountGroupAlarmNotificationDeliveryRuleRouter from '../services/account-group-alarm-notification-delivery-rule/routes';
import accountGroupAlarmNotificationDeliveryRuleContainer from '../services/account-group-alarm-notification-delivery-rule/container';
import containerUtils from '../../util/containerUtil';

export default (app, appContainer) => {
  const container = containerUtils.mergeContainers(appContainer, accountGroupAlarmNotificationDeliveryRuleContainer);

  app.use('/api/v1/accountgroupalarmnotificationdeliveryrules', container.get(AccountGroupAlarmNotificationDeliveryRuleRouter).router);
}
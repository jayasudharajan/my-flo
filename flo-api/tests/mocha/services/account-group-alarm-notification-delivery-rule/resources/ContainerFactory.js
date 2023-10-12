const inversify = require('inversify');
const AccountGroupAlarmNotificationDeliveryRuleTable = require('../../../../../dist/app/services/account-group-alarm-notification-delivery-rule/AccountGroupAlarmNotificationDeliveryRuleTable');
const AccountGroupAlarmNotificationDeliveryRuleService = require('../../../../../dist/app/services/account-group-alarm-notification-delivery-rule/AccountGroupAlarmNotificationDeliveryRuleService');

function ContainerFactory() {

  const container = new inversify.Container();

  container.bind(AccountGroupAlarmNotificationDeliveryRuleTable).to(AccountGroupAlarmNotificationDeliveryRuleTable);
  container.bind(AccountGroupAlarmNotificationDeliveryRuleService).to(AccountGroupAlarmNotificationDeliveryRuleService);

  return container;
}

module.exports = ContainerFactory;

import CrudService from '../utils/CrudService';
import AccountGroupAlarmNotificationDeliveryRuleTable from './AccountGroupAlarmNotificationDeliveryRuleTable';
import DIFactory from  '../../../util/DIFactory';

class AccountGroupAlarmNotificationDeliveryRuleService extends CrudService {
  constructor(accountGroupAlarmNotificationDeliveryRuleTable) {
    super(accountGroupAlarmNotificationDeliveryRuleTable);

    this.accountGroupAlarmNotificationDeliveryRuleTable = accountGroupAlarmNotificationDeliveryRuleTable; 
  }

  retrieveByGroupId(groupId) {
    return this.accountGroupAlarmNotificationDeliveryRuleTable.retrieveByGroupId(groupId)
      .then(({ Items }) => Items);
  }

  retrieveByGroupIdAlarmIdSystemMode(groupId, alarmId, systemMode) {
    return this.accountGroupAlarmNotificationDeliveryRuleTable.retrieveByGroupIdAlarmIdSystemMode(groupId, alarmId, systemMode)
      .then(({ Items }) => Items);
  }
}

export default new DIFactory(AccountGroupAlarmNotificationDeliveryRuleService, [AccountGroupAlarmNotificationDeliveryRuleTable]);
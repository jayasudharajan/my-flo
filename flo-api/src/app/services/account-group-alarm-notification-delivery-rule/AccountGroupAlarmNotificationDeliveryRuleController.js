import AccountGroupAlarmNotificationDeliveryRuleService from './AccountGroupAlarmNotificationDeliveryRuleService'
import DIFactory from  '../../../util/DIFactory';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';

class AccountGroupAlarmNotificationDeliveryRuleController extends CrudController {

  constructor(accountGroupAlarmNotificationDeliveryRuleService) {
    super(accountGroupAlarmNotificationDeliveryRuleService.accountGroupAlarmNotificationDeliveryRuleTable);

    this.accountGroupAlarmNotificationDeliveryRuleService = accountGroupAlarmNotificationDeliveryRuleService;
  }

  retrieveByGroupId({ params: { group_id } }) {
    return this.accountGroupAlarmNotificationDeliveryRuleService.retrieveByGroupId(group_id);
  }

  retrieveByGroupIdAlarmIdSystemMode({ params: { group_id, alarm_id, system_mode } }) {
    return this.accountGroupAlarmNotificationDeliveryRuleService.retrieveByGroupIdAlarmIdSystemMode(group_id, parseInt(alarm_id), parseInt(system_mode));
  }
}

export default new DIFactory(new ControllerWrapper(AccountGroupAlarmNotificationDeliveryRuleController), [ AccountGroupAlarmNotificationDeliveryRuleService ]);

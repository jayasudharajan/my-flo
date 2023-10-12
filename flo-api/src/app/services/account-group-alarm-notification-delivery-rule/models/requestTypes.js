import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TAccountGroupAlarmNotificationDeliveryRule from './TAccountGroupAlarmNotificationDeliveryRule'
import { createCrudReqValidation } from '../../../../util/validationUtils';

const TIntegerString = t.refinement(t.String, s => Number.isInteger(new Number(s).valueOf()));

export default {
  ...createCrudReqValidation(
    { 
      hashKey: 'group_id', 
      rangeKey: 'alarm_id_system_mode_user_role' 
    }, 
    TAccountGroupAlarmNotificationDeliveryRule.extend({
      alarm_id_system_mode_user_role: t.String
    })
  ),
  retrieveByGroupId: {
    params: t.struct({
      group_id: tcustom.UUIDv4
    })
  },
  retrieveByGroupIdAlarmIdSystemMode: {
    params: t.struct({
      group_id: tcustom.UUIDv4,
      alarm_id: TIntegerString,
      system_mode: TIntegerString
    })
  }
};







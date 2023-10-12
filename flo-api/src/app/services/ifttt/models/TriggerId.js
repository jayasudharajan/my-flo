import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TTriggerId = wrapEnum(t.enums({
  1: 'CRITICAL_ALERT_DETECTED',
  2: 'WARNING_ALERT_DETECTED',
  3: 'INFO_ALERT_DETECTED'
}));

export default TTriggerId;
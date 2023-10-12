import t from 'tcomb-validation';
import {wrapEnum} from '../../../../util/validationUtils';

const TStatus = wrapEnum(t.enums.of([
  'sent',
  'executed',
  'feedback_submitted',
  'learning',
  'insufficient_data',
  'internal_error'
]));

TStatus.STATUS_ORDER = [TStatus.sent, TStatus.executed, TStatus.feedback_submitted];

export default TStatus;
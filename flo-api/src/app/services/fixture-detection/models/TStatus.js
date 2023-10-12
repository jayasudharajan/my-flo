import t from 'tcomb-validation';
import {wrapEnum} from '../../../../util/validationUtils';

const TStatus = wrapEnum(t.enums.of([
  'sent',
  'executed',
  'feedback_submitted'
]));

export default TStatus;
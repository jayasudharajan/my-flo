import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { wrapEnum } from '../../../../util/validationUtils';

const TSubscriptionStatus = wrapEnum(t.enums.of([
  'trialing', 'active', 'past_due', 'canceled', 'unpaid'
]));

export default TSubscriptionStatus;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TCustomerEmailSubscription = t.struct({
  user_id: tcustom.UUIDv4,
  subscriptions: t.dict(t.String, t.Boolean)
});

TCustomerEmailSubscription.create = data => TCustomerEmailSubscription(data);

export default TCustomerEmailSubscription;
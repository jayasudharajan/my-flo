import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TSubscriptionPlan = t.struct({
  plan_id: t.String,
  features: t.list(t.String)
});

TSubscriptionPlan.create = data => TSubscriptionPlan(create);

export default TSubscriptionPlan;
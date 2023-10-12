import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAccountSubscription = t.struct({
  account_id: tcustom.UUIDv4,
  plan_id: t.String,
  status: t.String,
  stripe_customer_id: t.maybe(t.String),
  source_id: t.maybe(t.String),
  current_period_start: tcustom.ISO8601Date,
  current_period_end: tcustom.ISO8601Date,
  canceled_at: t.maybe(tcustom.ISO8601Date),
  ended_at: t.maybe(tcustom.ISO8601Date),
  cancel_at_period_end: t.maybe(t.Boolean),
  cancellation_reason: t.maybe(t.String)
});

TAccountSubscription.create = data => TAccountSubscription(create);

export default TAccountSubscription;
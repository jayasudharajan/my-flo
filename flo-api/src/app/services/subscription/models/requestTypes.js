import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TAccountSubscription from './TAccountSubscription'
import { createCrudReqValidation } from '../../../../util/validationUtils';

export default {
  ...createCrudReqValidation(
    { 
      hashKey: 'account_id', 
    }, 
    TAccountSubscription
  ),
  retrieveByUserId: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    })
  },
  handleStripeWebhookEvent: {
    body: t.Any
  },
  retrieveSubscriptionPlan: {
    params: t.struct({
      plan_id: t.String
    })
  },
  handleStripePayment: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    }),
    body: t.struct({
      stripe_token: t.maybe(t.String),
      plan_id: t.maybe(t.String),
      source_id: t.maybe(t.String),
      coupon_id: t.maybe(t.String)
    })
  },
  retrievePaymentSource: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    })
  },
  updatePaymentSource: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    }),
    body: t.struct({
      stripe_token: t.String
    })
  },
  retrieveCouponInfo: {
    params: t.struct({
      coupon_id: t.String
    })
  },
  cancelSubscriptionByUserId: {
    params: t.struct({
      user_id: tcustom.UUIDv4,
    })
  },
  cancelSubscriptionByUserIdWithReason: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    }),
    body: t.struct({
      reason: t.maybe(t.String)
    })
  }
};

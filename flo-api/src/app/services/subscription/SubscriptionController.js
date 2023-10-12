import DIFactory from  '../../../util/DIFactory';
import { CrudServiceController, ControllerWrapper } from '../../../util/controllerUtils';
import SubscriptionService from './SubscriptionService';

class SubscriptionController extends CrudServiceController {

  constructor(subscriptionService) {
    super(subscriptionService);

    this.subscriptionService = subscriptionService;
  }

  handleStripeWebhookEvent({ body }) {
    return this.subscriptionService.handleStripeWebhookEvent(body)
      .then(() => {});
  }

  handleStripePayment({ params: { user_id }, body }) {
    return this.subscriptionService.handleStripePayment({ ...body, user_id })
      .then(() => {});
  }

  retrieveByUserId({ params: { user_id } }) {
    return this.subscriptionService.retrieveByUserId(user_id);
  }

  retrieveSubscriptionPlan({ params: { plan_id } }) {
    return this.subscriptionService.retrieveSubscriptionPlan(plan_id);
  }

  retrieveCouponInfo({ params: { coupon_id } }){
    return this.subscriptionService.retrieveCouponInfo(coupon_id);
  }

  cancelSubscriptionByUserId({ params: { user_id } }) {
    return this.subscriptionService.cancelSubscriptionByUserId(user_id);
  }

  cancelSubscriptionByUserIdWithReason({ params: { user_id }, body: { reason } }) {
    return this.subscriptionService.cancelSubscriptionByUserId(user_id, reason);
  }

  retrievePaymentSource({ params: { user_id } }) {
    return this.subscriptionService.retrieveCreditCardByUserId(user_id);
  }

  updatePaymentSource({ params: { user_id }, body: { stripe_token } }) {
    return this.subscriptionService.updateCreditCardByUserId(user_id, stripe_token);
  }

}

export default new DIFactory(ControllerWrapper(SubscriptionController), [SubscriptionService]);
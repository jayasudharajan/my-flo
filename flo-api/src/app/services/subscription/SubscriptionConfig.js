
class SubscriptionConfig {
  constructor(config) {
    this.config = config;
  }

  getStripeWebhookSecret() {
    return Promise.resolve(this.config.stripeWebhookSignatureSecret);
  }

  getDefaultPlanId() {
    return Promise.resolve(this.config.subscriptionDefaultPlanId);
  }

  getDefaultSourceId() {
    return Promise.resolve(this.config.subscriptionDefaultSourceId);
  }
}

export default SubscriptionConfig;
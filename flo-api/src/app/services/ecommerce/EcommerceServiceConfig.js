export default class EcommerceServiceConfig {
  constructor(config) {
    this.config = config;
  }

  getOrderPaymentCompletedEmailTemplateId() {
    return Promise.resolve(this.config.orderPaymentCompletedEmailTemplateId);
  }
}
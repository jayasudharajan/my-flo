import StripeCient from 'stripe';
import DIFactory from  '../../../util/DIFactory';
import SubscriptionConfig from './SubscriptionConfig';
import ServiceException from '../utils/exceptions/ServiceException';

class StripeWebhookAuthMiddleware {

  constructor(stripeClient, subscriptionConfig) {
    this.stripeClient = stripeClient;
    this.subscriptionConfig = subscriptionConfig;
  }

  requiresAuth() {
    return (req, res, next) => {
      const signature = req.headers['stripe-signature'];

      this.subscriptionConfig.getStripeWebhookSecret()
        .then(secret => {
          const payload = req.rawBody;

          // Will throw StripeSignatureVerificationError exception if signature is invalid
          this.stripeClient.webhooks.constructEvent(payload, signature, secret);
          
          next();
        })
        .catch(err => {
          if (err.type == 'StripeSignatureVerificationError') {
            req.log.error({ err });
            return next(new ServiceException('Bad request.'));
          } else {
            return next(err);
          }
        });
    }
  }
}

export default new DIFactory(StripeWebhookAuthMiddleware, [StripeCient, SubscriptionConfig]);


import crypto from 'crypto';
import config from '../../../config/config'
import UnauthorizedException from '../utils/exceptions/UnauthorizedException';

class EcommerceAuthMiddleware {

  constructor() {
    this.secret = config.shopifySecretKey;
  }

  _hasValidShopifySignature(req) {
    const digest = crypto
      .createHmac('SHA256', this.secret)
      .update(req.rawBody)
      .digest('base64');

    return digest === req.get('x-shopify-hmac-sha256');
  }

  requiresAuth() {
    return (req, res, next) => {
      try {
        if (this._hasValidShopifySignature(req)) {
          return next();
        } else {
          return next(new UnauthorizedException());
        }
      } catch (err) {
        next(err);
      }
    };
  }
}

export default EcommerceAuthMiddleware;

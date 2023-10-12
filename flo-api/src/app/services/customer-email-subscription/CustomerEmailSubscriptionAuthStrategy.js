import AuthStrategy from '../utils/AuthStrategy';

export default class CustomerEmailSubscriptionAuthStrategy extends AuthStrategy {
  constructor(authMiddleware, controller) {
    super(authMiddleware, controller);

    this.retrieveAllEmails = (req, res, next) => next();
  }
}
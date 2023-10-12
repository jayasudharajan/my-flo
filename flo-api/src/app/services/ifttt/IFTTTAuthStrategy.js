import AuthStrategy from '../utils/AuthStrategy';
import config from '../../../config/config';
import UnauthorizedException from '../utils/exceptions/UnauthorizedException';

export default class IFTTTAuthStrategy extends AuthStrategy {
  constructor(authMiddleware, controller) {
    super(authMiddleware, controller);

    this.getStatus = (req, res, next) => {
      return this._checkIFTTTServiceKey(req, res, next);
    };

    this.testSetup = (req, res, next) => {
      return this._checkIFTTTServiceKey(req, res, next);
    };
  }

  _checkIFTTTServiceKey(req, res, next) {
    if(config.iftttServiceKey == req.get('ifttt-service-key')) {
      return next();
    } else {
      return next(new UnauthorizedException());
    }
  }
}


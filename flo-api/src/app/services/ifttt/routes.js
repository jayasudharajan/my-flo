import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware';
import IFTTTAuthStrategy from './IFTTTAuthStrategy';
import Router from '../utils/Router';
import ValidationStrategy from '../utils/ValidationStrategy';
import IFTTTController from './IFTTTController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import DIFactory from '../../../util/DIFactory';
import IFTTTACLStrategy from './IFTTTACLStrategy';
import IFTTTRouteMap from './IFTTTRouteMap';
import UnauthorizedException from '../utils/exceptions/UnauthorizedException';
import ValidationException from '../../models/exceptions/ValidationException';
import InvalidTokenException from '../oauth2/models/exceptions/InvalidTokenException';
import TokenExpiredException from '../oauth2/models/exceptions/TokenExpiredException';
import IFTTTAuthException from './models/exceptions/IFTTTAuthException';
import IFTTTValidationException from './models/exceptions/IFTTTValidationException';

class IFTTTRouter extends Router {
  constructor(authMiddleware, aclMiddleware, controller) {
    const auth = new IFTTTAuthStrategy(authMiddleware, controller);
    const validator = new ValidationStrategy({reqValidate}, requestTypes, controller);
    const acl = new IFTTTACLStrategy(aclMiddleware);
    const routeMap = new IFTTTRouteMap();

    super(auth, validator, acl, controller, routeMap);
  }

  handleError(controllerMethod) {
    return (err, res, req, next) => {
      if (err instanceof InvalidTokenException || err instanceof TokenExpiredException || err instanceof UnauthorizedException) {
        next(new IFTTTAuthException(err));
      } else if (err instanceof ValidationException) {
        next(new IFTTTValidationException(err));
      } else {
        next(err);
      }
    }
  }
}

export default new DIFactory(
  IFTTTRouter,
  [AuthMiddleware, ACLMiddleware, IFTTTController]
);
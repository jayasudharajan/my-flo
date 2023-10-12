import ServiceException from '../../../utils/exceptions/ServiceException';

class TokenExpiredException extends ServiceException {
  constructor() {
    super('Token expired.');
    this.status = 401;
  }
}

export default TokenExpiredException;
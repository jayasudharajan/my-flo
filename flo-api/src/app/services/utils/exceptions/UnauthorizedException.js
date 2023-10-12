import ServiceException from './ServiceException';

//Map to a HTTP 401 error
class UnauthorizedException extends ServiceException {
  constructor() {
    super('Unauthorized');
    this.status = 401;
  }
}

export default UnauthorizedException;
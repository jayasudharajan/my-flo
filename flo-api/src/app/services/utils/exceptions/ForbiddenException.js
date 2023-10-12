import ServiceException from './ServiceException';

class ForbiddenException extends ServiceException {
  constructor() {
    super('Forbidden');
    this.status = 403;
  }
}

export default ForbiddenException;
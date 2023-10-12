import ServiceException from './ServiceException';

//Map to a HTTP 409 error
class ConflictException extends ServiceException {
  constructor(message) {
    super(message);
    this.status = 409;
  }
}

export default ConflictException;
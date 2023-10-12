import ServiceException from './ServiceException';

//Map to a HTTP 409 error
class TooManyRequestsException extends ServiceException {
  constructor(message) {
    super(message);
    this.status = 429;
  }
}

export default TooManyRequestsException;
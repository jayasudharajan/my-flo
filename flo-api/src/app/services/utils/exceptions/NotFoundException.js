import ServiceException from './ServiceException';

//Map to a HTTP 404 error
class NotFoundException extends ServiceException {
  constructor(message) {
    super(message);
    this.status = 404;
  }
}

export default NotFoundException;
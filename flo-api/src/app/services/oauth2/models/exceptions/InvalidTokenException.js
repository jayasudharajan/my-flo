import ServiceException from '../../../utils/exceptions/ServiceException';

class InvalidTokenException extends ServiceException {
  constructor() {
    super('Invalid token.');
    this.status = 400;
  }
}

export default InvalidTokenException;
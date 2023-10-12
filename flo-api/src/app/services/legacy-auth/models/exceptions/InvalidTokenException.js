import ServiceException from '../../../utils/exceptions/ServiceException';

class InvalidTokenException extends ServiceException {
  constructor(message) {
    super(message || 'Invalid token.');
    this.status = 401;
  }
}

export default InvalidTokenException;
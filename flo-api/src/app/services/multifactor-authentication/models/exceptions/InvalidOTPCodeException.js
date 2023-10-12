import ServiceException from '../../../utils/exceptions/ServiceException';

class InvalidOTPCodeException extends ServiceException {
  constructor(message) {
    super(message || 'Invalid OTP code.');
    this.status = 401;
  }
}

export default InvalidOTPCodeException;
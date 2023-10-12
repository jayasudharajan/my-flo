import ServiceException from './ServiceException';

class MustBeLoggedInToOTPException extends ServiceException {
  constructor(message) {
    super(message || 'You must be logged in using otp before access to this resource');
    this.status = 401;
  }
}

export default MustBeLoggedInToOTPException;




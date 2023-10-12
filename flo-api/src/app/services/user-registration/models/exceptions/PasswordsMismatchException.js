import ServiceException from '../../../utils/exceptions/ServiceException';

class PasswordMismatchException extends ServiceException {
  constructor() {
    super('Passwords do not match.');
    this.status = 400;
  }
}

export default PasswordMismatchException;
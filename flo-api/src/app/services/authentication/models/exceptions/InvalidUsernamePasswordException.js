import ServiceException from '../../../utils/exceptions/ServiceException';

class InvalidUsernamePasswordException extends ServiceException {
  constructor() {
    super('Invalid username/password.');
    this.status = 400;
  }
}

export default InvalidUsernamePasswordException;
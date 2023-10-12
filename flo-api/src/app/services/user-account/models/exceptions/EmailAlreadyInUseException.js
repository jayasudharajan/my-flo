import ServiceException from '../../../utils/exceptions/ServiceException';

//Map to a HTTP 400 error
class EmailAlreadyInUseException extends ServiceException {
  constructor() {
    super('Email is already associated with a user.');
    this.status = 409;
  }
}

export default EmailAlreadyInUseException;
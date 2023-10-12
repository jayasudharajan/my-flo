import ServiceException from '../../../utils/exceptions/ServiceException';

class SessionExpiredException extends ServiceException {
  constructor() {
    super('Session expired.');
    this.status = 400;
  }
}

export default SessionExpiredException;
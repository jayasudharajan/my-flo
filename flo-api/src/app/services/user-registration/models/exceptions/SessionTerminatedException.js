import ServiceException from '../../../utils/exceptions/ServiceException';

class SessionTerminatedException extends ServiceException {
  constructor() {
    super('Session terminated.');
    this.status = 400;
  }
}

export default SessionTerminatedException;
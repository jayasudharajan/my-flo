import ExtensibleError from '../../../models/exceptions/ExtensibleError';

class ServiceException extends ExtensibleError {
  constructor(message) {
    super(message);
    this.status = 400;
  }
}

export default ServiceException;
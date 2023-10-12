import ServiceException from '../../../utils/exceptions/ServiceException';

class InvalidSessionException extends ServiceException {
  constructor(message) {
    super(message || 'Invalid session.');
    this.status = 400;
  }
}

export default InvalidSessionException;
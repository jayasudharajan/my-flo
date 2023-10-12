import ServiceException from '../../../utils/exceptions/ServiceException';

export default class IFTTTValidationException extends ServiceException {
  constructor(message) {
    super(message);
    this.status = 400;
    this.data = {
      errors: [{
        status: 'SKIP',
        message: message
      }]
    };
  }
}
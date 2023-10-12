import ServiceException from '../../../utils/exceptions/ServiceException';

export default class IFTTTValidationException extends ServiceException {
  constructor(err) {
    super(err.message);
    this.status = 400;
    this.data = {
      errors: [{message: err.message}]
    };
  }
}
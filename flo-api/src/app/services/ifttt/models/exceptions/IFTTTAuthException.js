import ServiceException from '../../../utils/exceptions/ServiceException';

export default class IFTTTAuthException extends ServiceException {
  constructor(err) {
    super(err.message);
    this.status = 401;
    this.data = {
      errors: [{message: err.message}]
    };
  }
}
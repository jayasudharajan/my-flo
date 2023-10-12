import ServiceException from '../../../utils/exceptions/ServiceException';

class OAuth2Error extends ServiceException {
  constructor(oauth2ErrorCode, httpStatusCode, message) {
    super(message);
    this.status = httpStatusCode;
    this.oauth2ErrorCode = oauth2ErrorCode;
  }
}

export default OAuth2Error;
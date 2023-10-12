import ServiceException from './ServiceException';

//Map to a HTTP 403 error
class MFARequiredException extends ServiceException {
  constructor(message, mfaToken) {
    super(message);
    this.status = 403;
    this.data = {
    	mfa_token: mfaToken
    };
  }
}

export default MFARequiredException;
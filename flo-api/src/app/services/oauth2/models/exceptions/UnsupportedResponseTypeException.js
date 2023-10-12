import OAuth2Error from './OAuth2Error';

class UnsupportedResponseTypeException extends OAuth2Error {
  constructor(message = 'Unsupported response type.') {
    super('unsupported_response_type', 501, message);
  }
}

export default UnsupportedResponseTypeException;
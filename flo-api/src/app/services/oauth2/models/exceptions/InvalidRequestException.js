import OAuth2Error from './OAuth2Error';

class InvalidRequestException extends OAuth2Error {
  constructor(message = 'Invalid request.') {
    super('invalid_request', 400, message);
  }
}

export default InvalidRequestException;
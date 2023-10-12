import OAuth2Error from './OAuth2Error';

class InvalidClientException extends OAuth2Error {
  constructor(message = 'Invalid client.') {
    super('invalid_client', 401, message);
  }
}

export default InvalidClientException;
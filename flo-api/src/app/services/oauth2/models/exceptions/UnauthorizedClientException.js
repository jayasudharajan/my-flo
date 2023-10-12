import OAuth2Error from './OAuth2Error';

class UnauthorizedClientException extends OAuth2Error {
  constructor(message = 'Unauthorized client.') {
    super('unauthorized_client', 403, message);
  }
}

export default UnauthorizedClientException;
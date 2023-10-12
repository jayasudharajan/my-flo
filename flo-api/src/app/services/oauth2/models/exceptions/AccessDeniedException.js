import OAuth2Error from './OAuth2Error';

class AccessDeniedException extends OAuth2Error {
  constructor(message = 'Access denied.') {
    super('access_denied', 403, message);
  }
}

export default AccessDeniedException;
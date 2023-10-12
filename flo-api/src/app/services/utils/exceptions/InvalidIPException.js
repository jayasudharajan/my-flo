import UnauthorizedException from './UnauthorizedException';

class InvalidIPException extends UnauthorizedException {
  constructor() {
    super();
  }
}

export default InvalidIPException;
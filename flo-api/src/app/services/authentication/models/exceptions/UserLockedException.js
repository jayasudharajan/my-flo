import ServiceException from '../../../utils/exceptions/ServiceException';

class UserLockedException extends ServiceException {
  constructor() {
    super('Your account has been locked. Please contact support.');
    this.status = 423;
  }
}

export default UserLockedException;
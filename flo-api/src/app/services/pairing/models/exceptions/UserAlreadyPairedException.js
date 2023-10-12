import ServiceException from '../../../utils/exceptions/ServiceException'

export default class UserAlreadyPairedException extends ServiceException {
  constructor() {
    super('User already paired.');
    this.status = 409;
  }
}
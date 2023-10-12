import ServiceException from '../../../utils/exceptions/ServiceException'

export default class DeviceAlreadyPairedException extends ServiceException {
  constructor() {
    super('Device already paired.');
    this.status = 409;
  }
}
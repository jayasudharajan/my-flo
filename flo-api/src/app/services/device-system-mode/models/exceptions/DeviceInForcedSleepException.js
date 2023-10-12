import ServiceException from '../../../utils/exceptions/ServiceException';

export default class DeviceInForcedSleepException extends ServiceException {
  constructor() {
    super('System mode cannot be changed. Please contact Flo Support for more information.');
    this.status = 409;
  }
}
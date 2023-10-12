import ServiceException from '../../../utils/exceptions/ServiceException';

class DeviceOfflineException extends ServiceException {
  constructor(deviceId) {
    super('Device offline.');
    this.data = { device_id: deviceId };
  }
}

export default DeviceOfflineException;
import DeviceStateService from './DeviceStateService'
import DIFactory from '../../../util/DIFactory';
import {ControllerWrapper} from '../../../util/controllerUtils';
import Logger from '../utils/Logger';

class DeviceStateController {

  constructor(deviceStateService, logger) {
    this.deviceStateService = deviceStateService;
    this.logger = logger;
  }

  forward({ body }) {
    return this.deviceStateService.forward(body)
      .catch(err => {
        this.logger.error({ err });
        return Promise.resolve({ error: err.message || true });
      });
  }

  pairingSync({ body }) {
    return this.deviceStateService.pairingSync(body);
  }
}

export default new DIFactory(new ControllerWrapper(DeviceStateController), [DeviceStateService, Logger]);

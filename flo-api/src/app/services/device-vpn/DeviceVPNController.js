import DeviceVPNService from './DeviceVPNService';
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class DeviceVPNController {
	constructor(vpnWhitelistService) {
	  this.vpnWhitelistService = vpnWhitelistService;
	}

  enable({ params: { device_id, user_id }, app_used }) {
    return this
      .vpnWhitelistService
      .enable(device_id, user_id, app_used);
  }

  disable({ params: { device_id, user_id }, app_used }) {
    return this
      .vpnWhitelistService
      .disable(device_id, user_id, app_used);
  }

  retrieveVPNConfig({ params: { device_id } }) {
    return this
      .vpnWhitelistService
      .retrieveVPNConfig(device_id);
  }
}

export default new DIFactory(new ControllerWrapper(DeviceVPNController), [DeviceVPNService]);
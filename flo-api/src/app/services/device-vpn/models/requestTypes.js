import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TByDevice = t.struct({
  device_id: tcustom.DeviceId
});

export default {
  enable: {
    params: TByDevice
  },
  disable: {
    params: TByDevice
  },
  retrieveVPNConfig: {
    params: TByDevice
  }
};
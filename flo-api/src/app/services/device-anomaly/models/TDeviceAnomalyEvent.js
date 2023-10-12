import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TDeviceAnomaly from './TDeviceAnomaly';

const TDeviceAnomalyEvent = t.struct({
  device_id: tcustom.DeviceId,
  time: tcustom.ISO8601Date,
  name: t.String,
  type: TDeviceAnomaly,
  level: t.String,
  duration: t.Integer,
  message: t.String,
});

export default TDeviceAnomalyEvent;
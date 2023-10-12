import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TDeviceStateLog = t.struct({
  id: tcustom.UUID,
  state_name: t.String,
  device_id: tcustom.DeviceId,
  current_state: t.Integer,
  previous_state: t.maybe(t.Integer),
  timestamp: t.Integer,
  reason: t.maybe(t.Integer),
  created_at: tcustom.ISO8601Date
});

export default TDeviceStateLog;
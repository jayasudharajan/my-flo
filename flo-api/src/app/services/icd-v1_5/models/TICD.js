import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TICD = t.struct({
	id: tcustom.UUIDv4,
	location_id: tcustom.UUIDv4,
	device_id: tcustom.DeviceId,
	is_paired: t.Boolean,
  target_system_mode: t.String,
  target_valve_state: t.String,
  revert_mode: t.String,
  revert_minutes: t.Number,
  revert_scheduled_at: tcustom.ISO8601Date
});

TICD.create = data => TICD(create);

export default TICD;
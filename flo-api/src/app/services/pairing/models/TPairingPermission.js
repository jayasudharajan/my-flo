import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TPairingPermission = t.struct({
  user_id: tcustom.UUIDv4,
  created_at: tcustom.ISO8601Date,
  ttl_mins: t.Integer,
  device_id: tcustom.DeviceId
});

TPairingPermission.create = data => TPairingPermission({ 
  created_at: new Date().toISOString(),
  ttl_mins: 30,
  ...data 
});

export default TPairingPermission;
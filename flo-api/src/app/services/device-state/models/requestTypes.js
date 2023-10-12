import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  forward: {
    body: t.struct({
      id: tcustom.UUID,
      sn: t.String,
      did: tcustom.DeviceId,
      st: t.Integer,
      pst: t.maybe(t.Integer),
      ts: t.Integer,
      rsn: t.maybe(t.Integer)
    })
  },

  pairingSync: {
    body: t.struct({
      device_id: tcustom.DeviceId,
      is_paired: t.Boolean,
      location_id: tcustom.UUIDv4
    })
  }
};
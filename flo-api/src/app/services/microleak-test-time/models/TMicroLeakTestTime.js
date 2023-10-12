import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TMicroLeakTestTime = t.struct({
  device_id: tcustom.DeviceId,
  times: t.list(t.Number),
  compute_time: tcustom.ISO8601Date,
  reference_time: t.struct({
    timezone: t.String,
    data_start_date: tcustom.ISO8601Date
  }),
  created_at: tcustom.ISO8601Date,
  created_at_device_id: t.String,
  is_deployed: tcustom.ZeroOrOne
});

export default TMicroLeakTestTime;
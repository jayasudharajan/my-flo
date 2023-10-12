import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  deployTimesConfig: {
    params: t.struct({
      device_id: tcustom.DeviceId
    }),
    body: t.struct({
      times: t.list(t.Number),
      compute_time: tcustom.ISO8601Date,
      reference_time: t.struct({
        timezone: t.String,
        data_start_date: tcustom.ISO8601Date
      })
    })
  },
}
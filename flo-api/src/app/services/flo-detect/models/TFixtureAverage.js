import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TFixtureAverage = t.struct({
  device_id: tcustom.DeviceId,
  start_date: tcustom.UUIDv4,
  end_date: tcustom.UUIDv4,
  duration_in_seconds: t.Integer,
  averages: t.dict(t.String, t.Number)
});

export default TFixtureAverage;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TStatus from './TStatus';
import TFixture from './TFixture';

const TFixtureDetectionLog = t.struct({
  request_id: tcustom.UUID,
  device_id: tcustom.DeviceId,
  start_date: tcustom.ISO8601Date,
  end_date: tcustom.ISO8601Date,
  fixtures: t.maybe(t.list(TFixture)),
  created_at: tcustom.ISO8601Date,
  status: TStatus
});

TFixtureDetectionLog.create = data => TFixtureDetectionLog(data);

export default TFixtureDetectionLog;
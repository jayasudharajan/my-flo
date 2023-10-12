import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TStatus from './TStatus';
import TFixture from './TFixture';
import TEvent from './TEvent';

const TFloDetectResult = t.struct({
  request_id: tcustom.UUID,
  device_id: tcustom.DeviceId,
  start_date: tcustom.ISO8601Date,
  end_date: tcustom.ISO8601Date,
  fixtures: t.maybe(t.list(TFixture)),
  status: TStatus,
  compute_start_date: t.maybe(tcustom.ISO8601Date),
  compute_end_date: t.maybe(tcustom.ISO8601Date),
  duration_in_seconds: t.maybe(t.Integer),
  event_chronology: t.maybe(t.list(TEvent))
});

TFloDetectResult.create = data => TFloDetectResult(data);

export default TFloDetectResult;
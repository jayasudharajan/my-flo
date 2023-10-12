import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TFixture from './TFixture';
import TEvent from './TEvent';

const TFixturesData = t.struct({
  request_id: tcustom.UUID,
  start_date: tcustom.ISO8601Date,
  end_date: tcustom.ISO8601Date,
  fixtures: t.maybe(t.list(TFixture)),
  compute_start_date: t.maybe(tcustom.ISO8601Date),
  compute_end_date: t.maybe(tcustom.ISO8601Date),
  duration_in_seconds: t.maybe(t.Integer),
  event_chronology: t.maybe(t.list(TEvent)),
  date_range: t.maybe(t.list(tcustom.ISO8601Date)),
  did: t.maybe(tcustom.DeviceId)
});

export default TFixturesData;
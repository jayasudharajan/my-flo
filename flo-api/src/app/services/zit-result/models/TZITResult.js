import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TZITResult = t.struct({
  icd_id: tcustom.UUIDv4,
  round_id: t.String,
  delta_pressure: t.maybe(t.Number),
  start_pressure: t.maybe(t.Number),
  end_pressure: t.maybe(t.Number),
  started_at: t.maybe(tcustom.ISO8601Date),
  ended_at: t.maybe(tcustom.ISO8601Date),
  event: t.maybe(t.String),
  leak_type: t.maybe(t.Number),
  test: t.String
});


export default TZITResult;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAwayModeStateLog = t.struct({
  icd_id: tcustom.UUIDv4,
  is_enabled: t.Boolean,
  times: t.maybe(t.list(t.list(tcustom.HourMinuteSeconds)))
});

export default TAwayModeStateLog;
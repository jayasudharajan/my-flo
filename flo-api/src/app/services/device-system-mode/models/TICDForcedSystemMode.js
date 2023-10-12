import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TICDForcedSystemMode = t.struct({
  icd_id: tcustom.UUIDv4,
  system_mode: t.maybe(t.Integer),
  performed_by_user_id: t.maybe(tcustom.UUIDv4)
});

TICDForcedSystemMode.create = data => TICDForcedSystemMode(data);

export default TICDForcedSystemMode;
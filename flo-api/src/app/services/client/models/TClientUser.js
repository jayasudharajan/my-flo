import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TClientUser = t.struct({
  client_id: tcustom.UUIDv4,
  user_id: tcustom.UUIDv4,
  is_disabled: t.maybe(tcustom.ZeroOrOne)
});

export default TClientUser;
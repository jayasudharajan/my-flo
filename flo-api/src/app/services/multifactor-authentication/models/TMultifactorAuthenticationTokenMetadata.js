import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TMultifactorAuthenticationTokenMetadata = t.struct({
  token_id: tcustom.UUIDv4,
  user_id: tcustom.UUIDv4,
  created_at: tcustom.ISO8601Date,
  expires_at: tcustom.ISO8601Date
});

TMultifactorAuthenticationTokenMetadata.create = data => TMultifactorAuthenticationTokenMetadata(data);

export default TMultifactorAuthenticationTokenMetadata;
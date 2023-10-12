import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TMultifactorAuthenticationMetadata = t.struct({
  user_id: tcustom.UUIDv4,
  secret: t.String,
  otp_auth_url: t.String,
  qr_code_data_url: t.String,
  is_enabled: tcustom.ZeroOrOne,
	created_at: tcustom.ISO8601Date
});

TMultifactorAuthenticationMetadata.create = data => TMultifactorAuthenticationMetadata(data);

export default TMultifactorAuthenticationMetadata;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAuthorizationCodeMetadata = t.struct({
	client_id: tcustom.UUIDv4,
	token_id: tcustom.UUIDv4,
	user_id: t.maybe(tcustom.UUIDv4),
	created_at: tcustom.ISO8601Date,
	expires_at: t.maybe(tcustom.ISO8601Date),
	redirect_uri: t.String
});

TAuthorizationCodeMetadata.create = data => TAuthorizationCodeMetadata(data);

export default TAuthorizationCodeMetadata;
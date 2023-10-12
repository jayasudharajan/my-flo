import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TRefreshTokenMetadata = t.struct({
	token_id: tcustom.UUIDv4,
	created_at: tcustom.ISO8601Date,
	expires_at: t.maybe(tcustom.ISO8601Date),
	user_id: tcustom.UUIDv4,
	client_id: tcustom.UUIDv4,
	access_token_id: tcustom.UUIDv4 
});

TRefreshTokenMetadata.create = data => TTokenMetadata(data);

export default TRefreshTokenMetadata;
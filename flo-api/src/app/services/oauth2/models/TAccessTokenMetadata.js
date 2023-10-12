import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAccessTokenMetadata = t.struct({
	user_id: t.maybe(tcustom.UUIDv4),
	token_id: tcustom.UUIDv4,
	created_at: tcustom.ISO8601Date,
	expires_at: t.maybe(tcustom.ISO8601Date),
	client_id: tcustom.UUIDv4,
	is_single_use: t.maybe(t.Boolean)
});

TAccessTokenMetadata.create = data => TTokenMetadata(data);

export default TAccessTokenMetadata;
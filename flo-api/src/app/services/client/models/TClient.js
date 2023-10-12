import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TGrant = t.enums.of([
	'implicit',
	'authorization_code',
	'client_credentials',
	'password',
	'refresh_token'
]);

const TClient = t.struct({
	client_id: tcustom.UUIDv4,
	client_secret: t.maybe(t.String),
	roles: t.list(t.String),
	grant_types: t.list(TGrant),
	name: t.String,
	client_type: t.Integer,
	scopes: t.maybe(t.list(t.String)),
	redirect_uri_whitelist: t.maybe(t.list(t.String)),
	is_login_restricted: t.maybe(t.Boolean),
	token_fields: t.maybe(t.list(t.String))
});

TClient.create = data => TClient(data);

export default TClient;
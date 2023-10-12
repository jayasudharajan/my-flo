import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TPasswordlessClient = t.struct({
	client_id: tcustom.UUIDv4,
	redirection_uri: t.String
});

TPasswordlessClient.create = data => TPasswordlessClient(data);

export default TPasswordlessClient;
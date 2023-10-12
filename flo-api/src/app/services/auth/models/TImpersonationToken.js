import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TAuthToken from './TAuthToken';

const TImpersonationToken = TAuthToken.extend(t.struct({
	impersonator: t.struct({
		user_id: tcustom.UUIDv4
	})
}));

TImpersonationToken.create = TAuthToken.create;

export default TImpersonationToken;


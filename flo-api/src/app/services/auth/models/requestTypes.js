import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
	impersonateUser: {
		params: t.struct({
			user_id: tcustom.UUIDv4
		}),
		body: t.struct({
			username: t.String,
			password: t.String
		})
	}
};

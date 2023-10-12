import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import moment from 'moment';

const TUserToken = t.struct({
	user_id: tcustom.UUIDv4,
	time_issued: t.Integer,
	expiration: t.Integer,
	user_agent: t.maybe(t.String),
	impersonator_user_id: t.maybe(tcustom.UUIDv4)
});

TUserToken.create = ({ timestamp = moment().unix(), ...props }) => TUserToken({ timestamp, ...props });

export default TUserToken;
import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TLoginAttemptStatus from './TLoginAttemptStatus';

const TUserLoginAttempt = t.struct({
	user_id: tcustom.UUIDv4,
	created_at: tcustom.ISO8601Date,
	status: TLoginAttemptStatus
});

TUserLoginAttempt.create = data => TUserLoginAttempt(data);

export default TUserLoginAttempt;
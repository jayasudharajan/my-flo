import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TLockStatus from './TLockStatus';

const TUserLockStatus = t.struct({
	user_id: tcustom.UUIDv4,
	created_at: tcustom.ISO8601Date,
	status: TLockStatus
});

TUserLockStatus.create = data => TUserLockStatus(data);

export default TUserLockStatus;
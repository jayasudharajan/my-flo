import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAccountRole = t.enums.of([
	'owner'
]);

const TUserAccountRole = t.struct({
	user_id: tcustom.UUIDv4,
	account_id: tcustom.UUIDv4,
	roles: t.list(TAccountRole)
});

TUserAccountRole.create = data => TUserAccountRole(data);

export default TUserAccountRole;
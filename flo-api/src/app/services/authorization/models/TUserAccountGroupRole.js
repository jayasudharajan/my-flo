import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAccountGroupRole = t.enums.of([
	'admin'
]);

const TUserAccountGroupRole = t.struct({
	user_id: tcustom.UUIDv4,
	group_id: tcustom.UUIDv4,
	roles: t.list(TAccountGroupRole)
});

TUserAccountGroupRole.create = data => TUserAccountRole(data);

export default TUserAccountGroupRole;
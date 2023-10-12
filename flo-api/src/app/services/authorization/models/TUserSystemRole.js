import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TSystemRole = t.enums.of([
	'admin'
]);

const TUserSystemRole = t.struct({
	user_id: tcustom.UUIDv4,
	roles: t.list(TSystemRole)
});

TUserSystemRole.create = data => TUserSystemRole(data);

export default TUserSystemRole;
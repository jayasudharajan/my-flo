import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TLocationRole = t.enums.of([
	'owner'
]);

const TUserLocationRole = t.struct({
	user_id: tcustom.UUIDv4,
	location_id: tcustom.UUIDv4,
	roles: t.list(TLocationRole)
});

TUserLocationRole.create = data => TUserLocationRole(data);

export default TUserLocationRole;
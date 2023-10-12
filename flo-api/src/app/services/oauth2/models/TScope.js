import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TResourceRole = t.struct({
	resource: t.String,
	role: t.String
});

const TScope = t.struct({
	scope_name: t.String,
	description: t.String,
	user_resource_roles: t.list(TResourceRole)
});

TScope.create = data => TScope(data);

export default TScope;
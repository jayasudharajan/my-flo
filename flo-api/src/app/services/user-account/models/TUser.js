import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TUserSource from './TUserSource';

const TUser = t.struct({
	id: tcustom.UUIDv4,
	email: tcustom.Email,
	password: t.maybe(t.union([tcustom.Password, tcustom.HashPassword])),
	is_active: t.maybe(t.Boolean),
  	source: t.maybe(TUserSource)
});

TUser.create = data => TUser(data);

export default TUser;
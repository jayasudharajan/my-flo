import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAccount = t.struct({
	id: tcustom.UUIDv4,
	owner_user_id: tcustom.UUIDv4,
	account_name: t.maybe(t.String),
	account_type: t.maybe(t.String),
	group_id: t.maybe(tcustom.UUIDv4)
});

TAccount.create = data => TAccount(data);

export default TAccount;
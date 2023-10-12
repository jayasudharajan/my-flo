import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TNotificationToken = t.struct({
	user_id: tcustom.UUIDv4,
	ios_tokens: t.maybe(t.list(t.String)),
	android_tokens: t.maybe(t.list(t.String))
});

export default TNotificationToken;
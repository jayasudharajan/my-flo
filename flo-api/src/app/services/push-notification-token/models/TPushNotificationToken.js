import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TPushNotificationToken = t.struct({
  mobile_device_id: t.String,
  client_id: tcustom.UUIDv4,
  user_id: tcustom.UUIDv4,
  token: t.String,
  client_type: t.Integer,
  is_disabled: t.maybe(tcustom.ZeroOrOne),
  aws_endpoint_id: t.maybe(t.String)
});

TPushNotificationToken.create = data => TPushNotificationToken(data);

export default TPushNotificationToken;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TPairingData = t.struct({
  id: t.String,
  ap_name: t.String,
  ap_password: t.maybe(t.String),
  device_id: t.String,
  login_token: t.String,
  client_cert: t.String,
  client_key: t.String,
  server_cert: t.String,
  websocket_cert: t.maybe(t.String),
  websocket_cert_der: t.maybe(t.String),
  websocket_key: t.String
});

TPairingData.create = data => TPairingData(data);

export default TPairingData;
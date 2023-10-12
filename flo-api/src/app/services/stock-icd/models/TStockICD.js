import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TStockICD = t.struct({
  id: t.String,
  icd_uuid: t.String,
  requested_at: tcustom.ISO8601Date,
  created_at: tcustom.ISO8601Date,
  qr_code_data_png: t.String,
  pairing_code: t.String,
  icd_client_cert: t.String,
  icd_client_key: t.String,
  icd_websocket_cert_der: t.String,
  wlan_mac_id: tcustom.MACAddress,
  device_id: tcustom.DeviceId,
  wifi_password: t.String,
  wifi_ssid: t.String,
  sku: t.String,
  icd_websocket_cert: t.String,
  icd_websocket_key: t.String,
  icd_login_token: t.String,
  ssh_private_key: t.maybe(t.String),
  flo_ca_version: t.String
}, 'TStockICD');

export default TStockICD;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TStockICDKafkaMessage = t.struct({
    id: t.String,
    icd_uuid: t.String,
    pairing_code: t.String,
    requested_at: tcustom.ISO8601Date,
    device_id: tcustom.DeviceId,
    wlan_mac_id: t.String,
    wifi_ssid: t.String,
    wifi_password: t.String,
    sku: t.String,
    websocket_key: t.String,
    websocket_cert: t.String,
    icd_login_token: t.String,
    ssh_private_key: t.maybe(t.String)
});

TStockICDKafkaMessage.create = data => TStockICDKafkaMessage(data);

export default TStockICDKafkaMessage;
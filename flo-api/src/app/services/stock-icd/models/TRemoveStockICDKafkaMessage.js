import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TRemoveStockICDKafkaMessage = t.struct({
  id: t.String,
  device_id: tcustom.DeviceId
});

TRemoveStockICDKafkaMessage.create = data => TRemoveStockICDKafkaMessage(data);

export default TRemoveStockICDKafkaMessage;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TDeviceSerialNumber = t.struct({
  device_id: tcustom.DeviceId,
  site: tcustom.SerialNumberCharacter,
  valve: tcustom.SerialNumberCharacter,
  pcba: tcustom.SerialNumberCharacter,
  product: tcustom.SerialNumberCharacter,
  date: tcustom.ISO8601Date,
  sn: t.String
});

export default TDeviceSerialNumber;
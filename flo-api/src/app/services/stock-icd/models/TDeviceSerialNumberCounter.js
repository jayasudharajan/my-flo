import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TDeviceSerialNumberCounter = t.struct({
  date: tcustom.ISO8601Date,
  counter: t.Integer
});

export default TDeviceSerialNumberCounter;
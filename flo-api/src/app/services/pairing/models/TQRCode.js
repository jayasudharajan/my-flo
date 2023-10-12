import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TQRCode = t.interface({
  i: t.String,
  e: t.String
});

export default TQRCode;
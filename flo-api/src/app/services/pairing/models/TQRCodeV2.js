import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TInteger2String = t.refinement(t.String, s => s == 2);

const TQRCodeV2 = t.struct({
  i: t.String,
  e: t.String,
  v: TInteger2String
});

export default TQRCodeV2;
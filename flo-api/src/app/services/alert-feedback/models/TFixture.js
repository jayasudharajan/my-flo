import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { wrapEnum } from '../../../../util/validationUtils';

const TFixture = t.enums.of([ 
  'irrigation',
  'shower/bath',
  'appliance',
  'pool/hot tub',
  'toilet',
  'faucet'
]);

export default wrapEnum(TFixture);
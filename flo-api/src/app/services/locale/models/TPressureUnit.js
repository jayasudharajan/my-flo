import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { wrapEnum } from '../../../../util/validationUtils';

const TPressureUnit = wrapEnum(t.enums({
  kPa: 'kPa',
  bar: 'Bar',
  psi: 'PSI'
}));

export default TPressureUnit;
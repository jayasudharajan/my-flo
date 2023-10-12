import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { wrapEnum } from '../../../../util/validationUtils';

const TVolumeUnit = wrapEnum(t.enums({
  L:'Liter',
  gal: 'Gallon'
}));

export default TVolumeUnit;
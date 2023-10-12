import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { wrapEnum } from '../../../../util/validationUtils';

const TTemperatureUnit = wrapEnum(t.enums({
  C: 'Celsius',
  F: 'Fahrenheit'
}));

export default TTemperatureUnit;
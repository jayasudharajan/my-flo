import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TSystemMode = wrapEnum(t.enums({
  2: 'HOME',
  3: 'AWAY',
  4: 'VACATION',
  5: 'SLEEP'
}));

export default TSystemMode;
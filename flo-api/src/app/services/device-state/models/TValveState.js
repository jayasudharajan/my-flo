import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TValveState = wrapEnum(t.enums.of([0, 1]), true);

export default TValveState;
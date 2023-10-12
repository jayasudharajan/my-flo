import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TLeakState = wrapEnum(t.enums.of([-1, 0, 1]), true);

export default TLeakState;
import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TSystemMode = wrapEnum(t.enums.of([2, 3, 5]), true);

export default TSystemMode;
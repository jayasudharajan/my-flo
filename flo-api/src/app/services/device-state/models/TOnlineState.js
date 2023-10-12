import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TOnlineState = wrapEnum(t.enums.of([0, 1]), true);

export default TOnlineState;
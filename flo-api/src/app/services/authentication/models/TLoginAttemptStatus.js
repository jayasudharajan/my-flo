import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TLoginAttemptStatus = wrapEnum(t.enums.of([
	'success',
	'fail',
	'reset'
]));

export default TLoginAttemptStatus;
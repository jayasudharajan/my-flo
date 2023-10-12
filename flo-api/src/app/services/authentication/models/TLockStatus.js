import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TLockStatus = wrapEnum(t.enums.of([
	'locked',
	'unlocked'
]));

export default TLockStatus;
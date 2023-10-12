import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TOnboardingEvent = wrapEnum(t.enums({
	1: 'paired',
	2: 'installed',
	3: 'systemModeUnlocked'
}));

export default TOnboardingEvent;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TOnboardingEvent from './TOnboardingEvent';

const TOnboardingLog = t.struct({
	icd_id: tcustom.UUIDv4,
	event: TOnboardingEvent
});

TOnboardingLog.create = data => TOnboardingLog(create);

export default TOnboardingLog;
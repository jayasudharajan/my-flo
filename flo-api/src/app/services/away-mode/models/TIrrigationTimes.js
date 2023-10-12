import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TIrrigationTimes = t.struct({
    times: t.list(t.list(tcustom.HourMinuteSeconds))
});

export default TIrrigationTimes;
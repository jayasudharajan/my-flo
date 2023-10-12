import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { createPartialValidator } from '../../../../util/validationUtils';
import TIrrigationTimes from './TIrrigationTimes';
import TIrrigationScheduleStatus from './TIrrigationScheduleStatus';

const TIrrigationSchedule = t.struct.extend([
    createPartialValidator(TIrrigationTimes),
    t.struct({
        status: TIrrigationScheduleStatus,
        device_id: tcustom.DeviceId
    })
]);

export default TIrrigationSchedule;

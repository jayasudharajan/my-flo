import t from 'tcomb-validation';
import { wrapEnum } from '../../../../util/validationUtils';

const TIrrigationScheduleStatus = t.enums.of([
    'schedule_found',
    'schedule_not_found',
    'no_irrigation_in_home',
    'learning',
    'internal_error'
]);

export default wrapEnum(TIrrigationScheduleStatus);
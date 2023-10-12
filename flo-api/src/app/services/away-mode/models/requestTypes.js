import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TIrrigationTimes from './TIrrigationTimes';

export default {
  retrieveIrrigationSchedule: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    })
  },
  enableDeviceAwayMode: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    }),
    body: TIrrigationTimes
  },
  disableDeviceAwayMode: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    })
  },
  retrieveAwayModeState: {
   params: t.struct({
      icd_id: tcustom.UUIDv4
    })  
  }
};
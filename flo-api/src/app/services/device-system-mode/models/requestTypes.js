import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  setSystemMode: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    }),
    body: t.struct({
      system_mode: t.Integer
    })
  },
  disableForcedSleep: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    })
  },
  enableForcedSleep: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    })
  },
  sleep: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    }),
    body: t.struct({
      sleep_minutes: t.Integer, 
      wake_up_system_mode: t.Integer
    })
  }
};
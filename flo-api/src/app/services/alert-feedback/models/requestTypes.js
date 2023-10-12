import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TAlertFeedback from './TAlertFeedback';

export default {
  submitFeedback: {
    body: TAlertFeedback
  },
  retrieveFeedback: {
    params: t.struct({
      icd_id: tcustom.UUID,
      incident_id: tcustom.UUID
    })
  },
  retrieveFlow: {
    params: t.struct({
      alarm_id: t.String,
      system_mode: t.String
    })
  }
};


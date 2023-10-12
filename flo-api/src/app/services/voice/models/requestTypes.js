import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  gatherUserAction: {
		params: t.struct({
      incident_id: t.String,
      user_id: tcustom.UUIDv4
    }),
    body: t.struct({
      Digits: t.String,
      CallSid: t.String
    })
	}
};
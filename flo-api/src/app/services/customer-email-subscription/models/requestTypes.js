import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  retrieve: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    }) 
  },
  updateSubscriptions: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    }),
    body: t.dict(t.String, t.Boolean)
  },
  retrieveAllEmails: {}
};
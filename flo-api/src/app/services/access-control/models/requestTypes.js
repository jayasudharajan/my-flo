import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  authorize: {
    body: t.struct({
      method_id: t.String,
      params: t.maybe(t.dict(t.String, t.Any))
    })
  },
  refreshUserRoles: {
    body: t.struct({
      user_id: tcustom.UUID
    })
  }
};
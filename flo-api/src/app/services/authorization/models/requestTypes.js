import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  retrieveUserAccountGroupRolesByGroupId: {
    params: t.struct({
      group_id: tcustom.UUIDv4
    })
  },
  retrieveUserAccountGroupRolesByUserId: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    })
  }
};
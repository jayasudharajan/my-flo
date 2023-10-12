import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TUserData from './TUserData';

export default {
	createNewUserAndAccount: {
		body: TUserData
	},
  removeUserAndAccount: {
    params: t.struct({
      user_id: tcustom.UUIDv4,
      account_id: tcustom.UUIDv4,
      location_id: tcustom.UUIDv4
    })
  }
};
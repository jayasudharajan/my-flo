import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TUserDetail from './TUserDetail';
import TUser from './TUser'
import TAccount from '../../account-v1_5/models/TAccount';
import TLocation from '../../location-v1_5/models/TLocation';
import TUserSource from './TUserSource';
import { createPartialValidator } from '../../../../util/validationUtils';

function extractPartialValidator(type, omitProps) {
  return createPartialValidator(t.struct(_.omit(type.meta.props, omitProps)));
}

const TUserData = t.struct.extend([
  _.pick(TUser.meta.props, ['email', 'password']),
  extractPartialValidator(TUser, ['id', 'email', 'password']),
	_.omit(TUserDetail.meta.props, ['user_id']),
  extractPartialValidator(TAccount, ['id', 'owner_user_id']),
  extractPartialValidator(TLocation, ['account_id', 'location_id'])
]);

TUserData.create = data => TUserData(data);

export default TUserData;
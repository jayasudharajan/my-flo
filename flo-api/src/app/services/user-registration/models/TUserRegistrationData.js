import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TMobileUserRegistrationData from './TMobileUserRegistrationData';
import TWebUserRegistrationData from './TWebUserRegistrationData';

const TUserRegistrationData = t.union([TMobileUserRegistrationData, TWebUserRegistrationData]);

TUserRegistrationData.create = data => TUserRegistrationData(data);

export default TUserRegistrationData;
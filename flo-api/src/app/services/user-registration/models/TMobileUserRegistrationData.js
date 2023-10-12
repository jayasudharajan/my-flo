import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TUserAuthData from './TUserAuthData';

const TMobileUserRegistrationData = t.interface.extend([
  TUserAuthData,
  t.struct({
    firstname: t.String,
    lastname: t.String,
    country: t.String,
    phone_mobile: t.String,
    skipEmailSend: t.maybe(t.Boolean),
    locale: t.maybe(t.String)
  })
]);

export default TMobileUserRegistrationData;
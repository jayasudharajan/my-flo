import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TUserAuthData from './TUserAuthData';

const TWebUserRegistrationData = t.interface.extend([
  TUserAuthData,
  t.struct({
    address: t.String,
    address2: t.maybe(t.String),
    city: t.String,
    state: t.String,
    country: t.String,
    postalcode: t.String,
    phone_mobile: t.maybe(t.String),
    locale: t.maybe(t.String)
  })
]);

export default TWebUserRegistrationData;
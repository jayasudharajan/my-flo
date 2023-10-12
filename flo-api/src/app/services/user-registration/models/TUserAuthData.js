import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TUserAuthData = t.refinement(
  t.struct({
    email: tcustom.Email,
    passwordHash: t.maybe(t.Boolean),
    password: t.union([tcustom.Password, tcustom.HashPassword]),
    password_conf: t.union([tcustom.Password, tcustom.HashPassword])
  }),
  ({ password, password_conf }) => password === password_conf
);

export default TUserAuthData;
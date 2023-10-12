import jwt from 'jsonwebtoken';
import uuid from 'uuid';
import TImpersonationToken from './models/TImpersonationToken';
import UserTokenTable from '../../models/UserTokenTable';
import config from '../../../config/config';
import { isAllowed } from '../../../util/aclUtils';

const UserToken = new UserTokenTable();

export function createImpersonationToken(user, impersonatorUserId) {
  const ttl = 3600; // 1 Hour
  const tokenData = TImpersonationToken.create({ 
    user: {
      user_id: user.id,
      email: user.email,
    },
    impersonator: {
      user_id: impersonatorUserId
    }
  });

  return UserToken.create({
  	user_id: tokenData.user.user_id,
  	time_issued: tokenData.timestamp,
  	expiration: ttl,
  	impersonator_user_id: impersonatorUserId,
    _is_ip_restricted: true
  })
  .then(() => {
	const token = jwt.sign(
	  tokenData,
	  config.tokenSecret,
	  { expiresIn: ttl }
	);

	return {
		token,
		timeNow: tokenData.timestamp,
		tokenExpiration: ttl
	};
  });
}
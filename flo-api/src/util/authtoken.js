import jwt from 'jsonwebtoken';
import _ from 'lodash';
import moment from 'moment';
import config from '../config/config';
import { isMobileUserAgent } from './httpUtil';
import useragent from 'useragent';
import SystemUserDetailTable from '../app/models/SystemUserDetailTable';

const systemUserDetail = new SystemUserDetailTable();

export function createAuthResponse(user, req) {
  const payload = { 
    user: {
      user_id: user.id,
      email: user.email,
    },
    timestamp: Math.round(moment().valueOf() / 1000)
  };

  // Create JWT token.
  return getTokenExpiration(user, req)
    .then(expiration => {
      const token = jwt.sign(
          payload,
          config.tokenSecret,
          { expiresIn: expiration }
      );

      // NOTE: most of this is for temp debugging.
      return {
        token: token,
        tokenPayload: payload,
        tokenExpiration: calcExpirationSeconds(expiration),
        timeNow: payload.timestamp
      };
    });
}

function calcExpirationSeconds(expirationStr) {
  const numDays = parseInt(expirationStr.split('d')[0]);

  return numDays * 24 * 60 * 60;
}

/**
 * Set expiration time to one year for known mobile OS, 
 * otherwise for one day (default in config).
 */
function getTokenExpiration(user, req) {
  const expTime = "1d"; //config.tokenExpirationTimeInSeconds;
  const thirtyDays = "30d"; //31536000;
  // TODO: FIX THIS! THIS SHOULD NOT GO INTO PRODUCTION

  if(isMobileUserAgent(req)) {
    return new Promise(resolve => resolve(thirtyDays));
  }

  return systemUserDetail.retrieve({ user_id: user.id })
    .then(({ Item }) => {
      if (Item && Item.token_ttl) {
        return Item.token_ttl;
      } else {
        return expTime;
      }
    });
}

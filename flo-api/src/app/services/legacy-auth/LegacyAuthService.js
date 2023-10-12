import _ from 'lodash';
import moment from 'moment';
import jwt from 'jsonwebtoken';
import config from '../../../config/config';
import UserTokenTable from './UserTokenTable';
import LegacyAuthStrategy from './LegacyAuthStrategy';
import AuthenticationService from '../authentication/AuthenticationService';
import SystemUserService from '../system-user/SystemUserService';
import InvalidTokenException from './models/exceptions/InvalidTokenException';
import TokenExpiredException from './models/exceptions/TokenExpiredException';
import DIFactory from  '../../../util/DIFactory';
import Logger from '../utils/Logger';

class LegacyAuthService {
  constructor(authenticationService, systemUserService, userTokenTable, logger) {
    this.authenticationService = authenticationService;
    this.systemUserService = systemUserService;
    this.userTokenTable = userTokenTable;
    this.logger = logger;
  }

  loginWithUsernamePassword(username, password, userAgent, isMobile, req = {}) {
    return this.authenticationService.verifyUsernamePassword(username, password, null, req)
      .then(user => this.issueToken(user, userAgent, isMobile));
  }

  issueToken(user, userAgent = '', isMobile = false) {
    const payload = {
      user: {
        user_id: user.id,
        email: user.email,
      },
      timestamp: moment().unix()
    };

    return this._getTokenExpiration(user, isMobile)
      .then(expiresIn => {
        const token = jwt.sign(
          payload,
          config.tokenSecret,
          { expiresIn }
        );
        
       return {
          token,
          tokenPayload: payload,
          tokenExpiration: calcExpirationSeconds(expiresIn),
          timeNow: payload.timestamp
        };
      })
      .then(tokenData => {

        return this.userTokenTable.create({
          user_id: user.id,
          time_issued: tokenData.tokenPayload.timestamp,
          expiration: tokenData.tokenExpiration,
          user_agent: userAgent,
          _is_ip_restricted: !!user._is_ip_restricted
        })
        .then(() => tokenData)
      });
  }

  _getTokenExpiration(user, isMobile) {
    const oneDay = '1d';
    const thirtyDays = '30d';

    if (isMobile) {
      return Promise.resolve(thirtyDays);
    } 

    return this.systemUserService.retrieveDetail(user.id)
      .then(detail => {
        if (detail && detail.token_ttl) {
          return detail.token_ttl
        } 

        return oneDay;
      });
  }

  verifyToken(token) {
    const deferredToken = Promise.defer();

    jwt.verify(token, config.tokenSecret, (err, decodedToken) => {
      if (err && err.name === 'TokenExpiredError') {
        this.logger.info({ legacy_auth_token_decoded: jwt.decode(token) });
        deferredToken.reject(new TokenExpiredException());
      } else if (err) {
        deferredToken.reject(new InvalidTokenException());
      } else {
        deferredToken.resolve(decodedToken);
      }
    });

    return deferredToken.promise
      .then(decodedToken => {
        const { user: { user_id }, timestamp } = decodedToken;

        return this.userTokenTable.retrieve({ user_id, time_issued: timestamp })
      })
      .then(({ Item: tokenMetadata = {} }) => {

        if (_.isEmpty(tokenMetadata)) {
          return Promise.reject(new InvalidTokenException('Token has been invalidated.'));
        }

        const expiration = parseInt(tokenMetadata.expiration || 0);
        const timeIssued = parseInt(tokenMetadata.time_issued || 0);
        const isTokenValid = expiration && moment().unix() < (expiration + timeIssued);
        
        if (!isTokenValid) {
          this.logger.info({ legacy_auth_token_metadata: tokenMetadata });
          return Promise.reject(new TokenExpiredException('Token has been expired.'));
        }

        return tokenMetadata;
      });
  }

  getAuthStrategy() {

    return new LegacyAuthStrategy(this);
  }
}

function calcExpirationSeconds(expirationStr) {
  const numDays = parseInt(expirationStr.split('d')[0]);
  const secondsInDay = 24 * 60 * 60;

  return numDays * secondsInDay;
}

export default new DIFactory(LegacyAuthService, [AuthenticationService, SystemUserService, UserTokenTable, Logger]);
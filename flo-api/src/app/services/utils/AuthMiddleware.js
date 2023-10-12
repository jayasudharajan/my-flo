//import _ from 'lodash';
import passport from 'passport';
import AuthorizationService from '../authorization/AuthorizationService';
import TokenExpiredException from '../legacy-auth/models/exceptions/TokenExpiredException';
import InvalidTokenException from '../legacy-auth/models/exceptions/InvalidTokenException';
//import ServiceException from '../utils/exceptions/ServiceException';
import DIFactory from '../../../util/DIFactory';
import config from '../../../config/config';
import { verifyIPAddress } from './utils';

class AuthMiddleware {
  constructor(authorizationService) {
    this.authorizationService = authorizationService;
  }

  _attemptLegacyAuth(req, res, next) {
    const deferred = Promise.defer();

    if(!config.legacyAuthDisabled) {
      passport.authenticate('legacy', { session: false }, (err, user, info) => {
        if (err && err.name === TokenExpiredException.name) {
          deferred.reject(err);
        } else if (err) {
          req.log.error({ err });

          deferred.resolve(null);
        } else {
          deferred.resolve({ user, info });
        }
      })(req, res, next);
    } else {
      deferred.resolve(null);
    }

    return deferred.promise;
  }

  _attemptOAuth2(req, res, next) {
      const deferred = Promise.defer();
      
      passport.authenticate('oauth2', { session: false }, (err, user, info) => {
        if (err) {
        deferred.reject(err);
        } else {
        deferred.resolve({ user, info });
        }
      })(req, res, next);

      return deferred.promise;
  }


  // This is all to support legacy endpoints that attach location/account/group IDs
  // and assume that a user only has 1 location or account
  _handleOptions(user, options = {}, req) {
    const {
      addUserId,
      addAccountId,
      addLocationId 
    } = options;

    if (addUserId) {
        req.params.user_id = user.user_id
    }

    req.authenticated_user = user;

    return Promise.all([
        addAccountId ? 
          this._retrieveAccounts(user.user_id)
          .then(([ account_id ]) => req.params.account_id = account_id) :
          Promise.resolve([]),
        addLocationId ?
          this._retrieveLocations(user.user_id)
            .then(([ location_id ]) => req.params.location_id = location_id) :
          Promise.resolve([])
    ]);
  }

  /** Double Secret Hack for Alexa. SEE: https://gpgdigital.atlassian.net/browse/DT-355 **/
  swapClientSecret() {
      return (req, res, next) => {
          try {
              const dsClientId = process.env.FLO_DOUBLE_SECRET_CLIENT_ID;
              const dsOldSecret = process.env.FLO_DOUBLE_SECRET_OLD;
              const dsNewSecret = process.env.FLO_DOUBLE_SECRET_NEW;
              if(dsClientId && dsOldSecret && dsNewSecret && dsNewSecret.length > 0) {
                  //req.log.debug(`swapClientSecret_enter with client_id ${dsClientId}`);
                  const cutOffDt = new Date(process.env.FLO_DOUBLE_SECRET_CUTOFF || "2021-12-01T00:00:00.000Z"); //default expiration in December 2021
                  let swapOK = false;

                  if(req && cutOffDt.getFullYear() >= 2021 && new Date().valueOf() < cutOffDt.valueOf()) {
                      const { client_id, client_secret } = req.body;
                      if(client_id && client_secret && client_id.toLowerCase() === dsClientId.toLowerCase() && client_secret === dsOldSecret) {
                          req.body.client_secret = dsNewSecret; //secret swap here
                          swapOK = true;
                          req.log.info(`swapClientSecret_OK for client_id ${dsClientId}`);
                      }
                  }
                  if(!swapOK) {
                      req.log.debug(`swapClientSecret_skip client_id ${dsClientId}`);
                  }
              }
          } catch (e) { //we're only going to print error & move on!
              const { client_id } = req.body;
              req.log.warn(`swapClientSecret_failed for client_id ${client_id}`, e);
          }
          return next(); //always execute next for this middleware
      };
  }

  requiresAuth(options) {

    return (req, res, next) => {
        try {

            // Allow OAuth tokens to be passed as base64 in the querystring
            // This should only be used for single use tokens!
            if (!req.get('Authorization') && req.query.t) {
              req.headers.authorization = `Bearer ${ Buffer.from(req.query.t, 'base64').toString() }`;
            }

            this._attemptLegacyAuth(req, res, next)         
              .then(result => {
                  if (result) {
                      return result;
                  }

                  return this._attemptOAuth2(req, res, next);       
              })
              .then(({ user, info }) => {

                if (info) {
                  req.token_metadata = info;
                  req.log = req.log.child({ token_metadata: info });
                }

                if (!user) {
                    return Promise.reject(new InvalidTokenException());
                }

                return verifyIPAddress({ _is_ip_restricted: info._is_ip_restricted }, req)
                  .then(() => ({ user, info }));
              })
              .then(({ user }) =>  {
 
                // Temporary hack to prevent long-lived unsubscribe tokens from being used with 
                // the /me endpoints that do not use ACL
                if (req.token_metadata.disallow_me && req.originalUrl.split('/').indexOf('me') >= 0) {
                  return Promise.reject(new InvalidTokenException());
                }

                req.user = req.user || user;

                return this._handleOptions(user, options, req);
              })
              .then(() => next())
              .catch(next);
        } catch (err) {
            next(err);
        }
      };
  }

  _retrieveAccounts(userId) {
    return this.authorizationService.retrieveUserResources(userId, 'Account');
  }

  _retrieveLocations(userId) {
    return this.authorizationService.retrieveUserResources(userId, 'Location');
  }
}

export default new DIFactory(AuthMiddleware, [AuthorizationService]);
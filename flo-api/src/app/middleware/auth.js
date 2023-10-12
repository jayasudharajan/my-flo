import jwt from 'jsonwebtoken';
import _ from 'lodash';
import config from '../../config/config';
import { extractAccountInfo, extractLocationInfo } from '../../util/utils';
import { getClient, withFallback } from '../../util/cache';
import { userRoles, addUserRoles, createSubResourceRole, parseSubResourceRole } from '../../util/aclUtils';
import UserTokenTable from '../models/UserTokenTable';
import UserAccountRoleTable from '../models/UserAccountRoleTable';
import UserLocationRoleTable from '../models/UserLocationRoleTable';
import UserAccountGroupRoleTable from '../models/UserAccountGroupRoleTable';

/**
 * Secure endpoint via basic user/role combo.
 *
 * @param  {String} role  (comma delimited) string of roles.
 * @return {function}     next
 */
export function requiresAuth(options) {

    return function(req, res, next){
        try {

            // Get authorization token from header.
            let token = '';
            if (req.headers.authorization) {
                token = req.headers.authorization;
            }

            // Decode.
            let decoded_token = jwt.verify(token, config.tokenSecret);
            let user_id = decoded_token.user.user_id;
            let time_issued = decoded_token.timestamp;

            req.decoded_token = decoded_token;

            retrieveTokenDetails(user_id, time_issued, req.log)
                .then(({ expiration }) => {
                    let timeIssuedSecs = parseInt(time_issued);
                    let now = Math.round(new Date().getTime() / 1000);

                    return expiration && now < (parseInt(expiration, 10) + timeIssuedSecs);
                })
                .then(isTokenValid => {
                    let promises = [];

                    if (isTokenValid) {

                        req.authenticated_user = decoded_token.user;

                        if (options && options.addUserId) {
                            req.params["user_id"] = decoded_token.user.user_id;
                        }

                        if (options && options.addAccountId) {

                            promises.push(
                                retrieveAccounts(user_id, req.log)
                                    .then(accountIds => {
                                        req.params["account_id"] = accountIds[0];
                                    })
                            );
                        }

                        if (options && options.addLocationId) {

                            promises.push(
                                retrieveLocations(user_id, req.log)
                                    .then(locationIds => {
                                        req.params["location_id"] = locationIds[0];
                                    })
                            );
                        }

                        if (options && options.addAccountGroupId) {

                            promises.push(
                                retrieveAccountGroup(user_id, req.log) 
                                    .then(groupIds => {
                                        req.params["group_id"] = groupIds[0];
                                    })
                            );
                        }

                        if (promises.length) {

                            return Promise.all(promises).then(() => {
                                next();
                            });
                        } else {
                            return next();
                        }

                    } else {
                        return next({ status: 401, message: 'Authorization token invalidated.' });
                    }

                })
                .catch(err => {
                    next(err);
                });

            // console.log('----- DECODED TOKEN -----');
            // console.log(decoded_token);

            // Always extract the user from token and attach to request.


        } catch (error) {
            switch (error.name) {
                case 'TokenExpiredError':
                    next({ status: 401, message: 'Authorization token expired.', expiredAt: error.expiredAt  });  // TESTING
                    break;
                case 'JsonWebTokenError':
                    next({ status: 401, message: 'Unauthorized.  Bad or not present token.'  });
                    break;
                default:
                    next({ status: 500, message: error.message  });  //, details: error.toStackTrace()
            }
        }

    }

}

export function replaceMeWithUserId(param) {
    return (req, res, next) => {
        if (req.params[param].toLowerCase() === 'me') {
            req.params[param] = req.authenticated_user.user_id;
        } 

        next();
    }
}

function retrieveTokenDetails(user_id, time_issued, log) {
    return new UserTokenTable().retrieve({ user_id, time_issued })
        .then(data => {
            const { Item } = data;
            
            return Item || { expiration: 0 }
        });
}


function retrieveAccounts(user_id, log) {

    return retrieveResources(
        user_id,
        'Account',
        createFallback(user_id, new UserAccountRoleTable(), 'Account', 'account_id'),
        log
    );
}

function retrieveLocations(user_id, log) {

    return retrieveResources(
        user_id,
        'Location',
        createFallback(user_id, new UserLocationRoleTable(), 'Location', 'location_id'),
        log
    );
}

function retrieveAccountGroup(user_id, log) {

    return retrieveResources(
        user_id,
        'AccountGroup',
        createFallback(user_id, new UserAccountGroupRoleTable(), 'AccountGroup', 'group_id'),
        log
    );
}

function createFallback(userId, model, resourceType, key) {

    return () => model.retrieveByUserId({ user_id: userId })
        .then(({ Items }) => 
            Items.map(item => 
                item.roles.map(role => ({ resourceType, role, resourceId: item[key] }))
            )
            .reduce((acc, parsedRoles) => acc.concat(parsedRoles), [])
        );
}

function retrieveResources(userId, resourceType, fallback, log) {
    return withFallback(
        () => lookupResources(userId, resourceType).then(roles => !roles.length ? null : roles),
        () => fallback(),
        parsedRoles => cacheResources(userId, resourceType, parsedRoles)
            .catch(err => {
                if (log) {
                    log.error({ err });
                }
            }),
        log && ((isFromCache, result) => log.info({ cached_lookup: { isFromCache, result } }))
    )
    .then(parsedRoles => {
        return parsedRoles.map(({ resourceId }) => resourceId);
    });
}

function lookupResources(userId, resourceType) {
    return userRoles(userId)
        .then(roles => roles
            .map(parseSubResourceRole)
            .filter(parsedRole => parsedRole.resourceType === resourceType)
        );
}

function cacheResources(userId, resourceType, parsedRoles) {
    let subResourceRoles = parsedRoles.map(({ resourceType, resourceId, role }) => createSubResourceRole(resourceType, resourceId, role));

    return addUserRoles(userId, subResourceRoles);
}
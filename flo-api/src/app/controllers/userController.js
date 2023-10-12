import _ from 'lodash';
import passport from 'passport';
import moment from 'moment';
import jwt from 'jsonwebtoken';

import UserTable from '../models/UserTable';
import ResetTokenTable from '../models/ResetTokenTable';
import NotificationTokenTable from '../services/notification-token/NotificationTokenTable';
import UserDetailTable from '../models/UserDetailTable';

import UserUtilsTable from '../models/UserUtilsTable';
import UserAccountRoleTable from '../models/UserAccountRoleTable';
import UserLocationRoleTable from '../models/UserLocationRoleTable';
import UserAccountGroupRoleTable from '../models/UserAccountGroupRoleTable';
import SystemUserDetailTable from '../models/SystemUserDetailTable';

import RegistrationTokenTable from '../models/RegistrationTokenTable';
import LocationTable from '../models/LocationTable';

import ICDTable from '../models/ICDTable';

import UserTokenTable from '../models/UserTokenTable'

import { filterUser, isMobileUserAgent } from '../../util/httpUtil';
import { createAuthResponse } from '../../util/authtoken';
import { generateRandomToken } from '../../util/encryption';
import { extractAccountInfo, extractLocationInfo } from '../../util/utils';
import config from '../../config/config';

import { replaceUserRoles, createSubResourceRole, userRoles } from '../../util/aclUtils';

import { getClient } from '../../util/cache';
import ResourceCache from '../../util/resourceCache';
import { checkPassword } from '../../util/utils';
import { getLockStatus, setLockStatus, LOCK_STATUS } from '../../util/userLockStatus';
import { resetCount } from '../../util/userLoginAttempt';
import sendwithus from 'sendwithus';
import NotFoundException from '../services/utils/exceptions/NotFoundException';

import legacyAuthContainer from '../services/legacy-auth/container';
import LegacyAuthService from '../services/legacy-auth/LegacyAuthService';
import AuthenticationService from '../services/authentication/AuthenticationService';

import userAccountContainer from '../services/user-account/container';
import UserAccountService from '../services/user-account/UserAccountService';
import { verifyIPAddress } from '../services/utils/utils';

const legacyAuthService = legacyAuthContainer.get(LegacyAuthService);
const userAccountService = userAccountContainer.get(UserAccountService);
const authenticationService = legacyAuthContainer.get(AuthenticationService);


let user = new UserTable();
let userUtils = new UserUtilsTable();
let resetToken = new ResetTokenTable();
let notificationToken = new NotificationTokenTable();
let userDetail = new UserDetailTable();
let userAccountRole = new UserAccountRoleTable();
let userLocationRole = new UserLocationRoleTable();
let userAccountGroupRole = new UserAccountGroupRoleTable();
let systemUserDetail = new SystemUserDetailTable();
let registrationToken = new RegistrationTokenTable();
let location = new LocationTable();
let ICD = new ICDTable();
let userToken = new UserTokenTable();
const sendwithusClient = sendwithus(config.email.sendwithus.api_key);

let resourceCache = new ResourceCache(getClient());

export function authenticate(req, res, next) {
  const { body: { username, password } } = req;
  const userAgent = req.headers['user-agent'];
  const isMobile = isMobileUserAgent(req);

  legacyAuthService.loginWithUsernamePassword(username, password, userAgent, isMobile, req)
    .then(result => res.json(result))
    .catch(next);
}

export function performMFAChallenge(req, res, next) {
  const { user: { user_id } } = req;
  const userAgent = req.headers['user-agent'];
  const isMobile = isMobileUserAgent(req);

  userAccountService.retrieveUser(user_id)
    .then(user => verifyIPAddress(user, req))
    .then(user => legacyAuthService.issueToken(user, userAgent, isMobile))
    .then(result => res.json(result))
    .catch(next);
}

export function logout(req, res, next) {
  let { notification_token } = req.body;
  let { user_id } = req.params;

  // Fetch the 'time_issued' from the auth token.
  // Find the user token and invalidate the expiration.
  // Remove a notification token if present.
  Promise.all([
    req.token_metadata.time_issued && userToken.patch(
      { user_id, time_issued: parseInt(req.token_metadata.time_issued) }, 
      { expiration: 0 }
    ),
    notification_token && notificationToken.removeToken(user_id, notification_token)
      .catch(err => {
        if (err.statusCode === 404) {
          return Promise.resolve();
        } else {
          return Promise.reject(err);
        }
      })
  ])
  .then(() => { res.status(200).json(); })
  .catch(next);
}

export function updateLockStatus(req, res, next) {
  const { user_id } = req.params;
  const { is_locked } = req.body;

  return Promise.all([
      setLockStatus(user_id, is_locked ? LOCK_STATUS.LOCKED : LOCK_STATUS.UNLOCKED)
    ].concat(is_locked ? [] : [resetCount(user_id)])
  )
  .then(() => res.send())
  .catch(err => next(err));
}

export function retrieveLockStatus(req, res, next) {
  const { user_id } = req.params;

  return getLockStatus(user_id)
    .then(lockStatus => res.json({ is_locked: lockStatus === LOCK_STATUS.LOCKED }))
    .catch(err => next(err));
}

function parseRoles(resourceType, resourceId, roleRecords) {
  return (roleRecords || [])
    .map(record => 
      (record.roles || []).map(role => createSubResourceRole(resourceType, record[resourceId], role))
    )
    .reduce((acc, roles) => acc.concat(roles), []);
}

/**
 * 'UI Permissions' - v1
 *
 * Returns a simple identifier if a user is a sys admin or 
 * group admin for the purpose of the Site Admin.
 */
export function getUIPermissions(req, res, next) {
  const id = req.params.user_id;

  user.retrieve({ id })
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {

        return userRoles(id);
      }
    })
    .then(roles => {
        // User is a System Admin.
        if (roles.indexOf('system.admin') >= 0) {
          return res.json({ p: 'sa' });
        } else {

          // Fetch AccountGroups.
          return userAccountGroupRole.retrieveByUserId({ user_id: id })
            .then(accountGroups => {

              // User is a Group Admin.
              if(!_.isEmpty(accountGroups.Items)) {

                // Extract group IDs.
                let groupIds = [];
                for(let group of accountGroups.Items) {
                  if(group.group_id) {
                    groupIds.push(group.group_id);
                  }
                }
                return res.json({ p: 'ga', g: groupIds });

              // Normal User.
              } else {
                return res.json({ p: 'usr' });
              }
            });
        }
    })
    .catch(err => {
      next(err);
    });

}

/**
 * Retrieve one user.
 */
export function retrieve(req, res, next) {

  const id = req.params.user_id;
  user.retrieve({ id })
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(filterUser(result.Item));
      }
    })
    .catch(err => {
      next(err);
    });

}

/**
 * Retrieve user only by email (username).
 */
export function getUserByEmail(req, res, next) {

  const { email } = req.params;

  user.getUserByEmail(email)
    .then(result => {
      if(_.isEmpty(result.Items)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(filterUser(result.Items[0]));  //filterUser(result.Item)
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create one user.
 */
export function create(req, res, next) {

  if(!_.isEmpty(checkedPassword)) {
    next(checkedPassword);
  } else {

    user.create(req.body)
      .then(result => {
        res.json(filterUser(result));
      })
      .catch(err => {
        next(err);
      });
  
  }
}

/**
 * Update one item completely.
 * 
 * NOTE: This is basically a create that checks if keys are present.
 */
export function update(req, res, next) {

  const id = req.params.user_id;

  // Add url keys into request body.
  // TODO: do we need to make sure param and body match?
  req.body.id = id;

  let checkedPassword = checkPassword(req.body.password);
  if(!_.isEmpty(checkedPassword)) {
    next(checkedPassword);
  } else {

    user.update(req.body)
      .then(result => {
        res.json(result);
      })
      .catch(err => {
        next(err);
      });
  }
}

/**
 * Patch one user.
 */
export function patch(req, res, next) {
  const id = req.params.user_id;
  let data = req.body;

  let checkedPassword = req.body.password && checkPassword(req.body.password);
  if(req.body.password && !_.isEmpty(checkedPassword)) {
    next(checkedPassword);
  } else {

    user.patch({ id }, data)
      .then(result => {
        res.json(result);
      })
      .catch(err => {
        next(err);
      });
  }

}

/**
 * Delete one user.
 */
export function remove(req, res, next) {

  const id = req.params.user_id;
  
  user.remove({ id: id })
    .then(result => {
      if(!result) {
        next({ status: 404, message: "Item not found."  });
      } else {
        // notification may not exist
        notificationToken.remove({ user_id: id });
        res.json(result);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Archive ('delete') one user.
 */
export function archive(req, res, next) {

  const id = req.params.user_id;
  
  user.archive({ id: id })
    .then(result => {
      // TODO: discuss what JSON package should be returned.
      // { Attributes: { is_deleted: true } }
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(result);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * TEMP - Simple Table scan to retrieve multiple records.
 */
export function scan(req, res, next) {

  user.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

// TEMP
export function scanEmail(req, res, next) {

  user.scanEmail()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * TEMP - Simple Table scan to retrieve multiple records.
 */
export function scanResetToken(req, res, next) {
  resetToken.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

function requestPasswordResetAction(reset_path, req, res, next) {

  const email = req.body.email;
  const templateId = req.body.templateId || config.email.sendwithus.templates.forgot_password;
  const token = generateRandomToken(20);

  // NOTE: sending default message regardless of success or failure.
  const defaultMsg = { message: "If the account exists, a password reset email was sent to " + email + "."};

  user.getUserByEmail(email)
    .then(result => {

      if(_.isEmpty(result.Items)) {
        return Promise.reject(new NotFoundException('User not found.'));
      } 

      const foundUser = result.Items[0];
      const payload = {
        user_id: foundUser.id,
        reset_password_token: token,
        reset_password_expires: moment().add(60, 'm').format("YYYY-MM-DD HH:mm:ss") // .utc()?
      };

      return resetToken.create(payload).then(() => foundUser);      
    })
    .then(foundUser => {
      const options = {
        email_id: templateId,
        recipient: { address: email },
        email_data: {
          email_address: email,
          reset_link: reset_path + '/passwordreset/' + foundUser.id + '/' + token,
          contact_link: config.contact_url
        },
        sender: {
          address: config.email.sender,
          name: config.email.company
        }
      };
      const emailDeferred = Promise.defer();

      sendwithusClient.send(options, (err, response) => {

        if (err) {
          emailDeferred.reject(err);
        } else {
          emailDeferred.resolve();
        }
      });

      return emailDeferred.promise;
    })
    .then(() => res.json(defaultMsg))
    .catch(err => {
      if (err instanceof NotFoundException) {
        req.log.error({ err });
        res.json(defaultMsg);
      } else {
        next(err);
      }
    });
}

/**
 * Initial reset password request.
 */
export function requestPasswordReset(req, res, next) {
  return requestPasswordResetAction(config.admin_url, req, res, next);
}

export function requestPasswordResetUser(req, res, next) {
  const app = req.body.app || 'user_portal';
  return requestPasswordResetAction(app === 'mud' ? config.mud_url : config.user_portal_url, req, res, next);
}

/**
 * Validate a password reset token and return an auth token.
 *
 * TODO: log validation attempt.
 */
export function validateResetToken(req, res, next) {

  const { user_id, token } = req.params;

  // Fetch the reset token.
  resetToken.retrieveByToken(token)
    .then(result => {

      if(_.isEmpty(result.Items)) {
        throw({ statusCode: "404", message: "Invalid token." });
      } else {

        // TODO: QA against UTC time.
        let now = moment();
        let token_time = moment(result.Items[0].reset_password_expires);
        //console.log(now.diff(token_time, 'minutes'));

        // If token didn't expire (60? minutes), remove all reset tokens for user.
        if(now.diff(token_time, 'minutes') < 0) {
          return resetToken.remove({ user_id });
          // TEMP - don't delete while testing.
          //return new Promise((resolve, reject) => { resolve({ message: "DELETING TOKEN" }) });
        } else {
          throw({ message: "Reset token expired." });
        }
      }

    })
    .then(result => {
      // Fetch user.  NOTE: key is 'id'.
      return userUtils.retrieveUserForAuthToken(user_id);
    })
    .then(userinfo => {
      return Promise.all([
        legacyAuthService.issueToken(userinfo, req.headers['user-agent'], isMobileUserAgent(req)),
        authenticationService.unlockUser(user_id)
      ]);
    })
    .then(([authResponse]) => {
      return res.json(authResponse);
    })
    .catch(err => {
      if(err.statusCode) {
        req.log.error({ err });
        next({ status: err.statusCode, message: err.message  });
      } else {
        next(err);
      }
    });

}

export function sendRegistrationMail(req, res, next) {
  // Get User info.
  // Create RegistrationTokens for User.
  // Create and send email.

  // Will we have user_id or just email?
  let { user_id } = req.body;
  let this_user = {};

  // TODO: validation.

  // Get user to validate and get email.
  user.retrieve({ id: user_id })
    .then(result => {
      if(!_.isEmpty(result)) {
        this_user = result.Item;

        // Create a registrationToken.
        return registrationToken.create({ user_id });
      } else {
        return new Promise((resolve, reject) => {
          reject({ message: "User not found."})
        });
      }
    })
    // Create and send email.
    .then(regToken => {

      if(!_.isEmpty(regToken)) {

        var email_api = require('sendwithus')(config.email.sendwithus.api_key);
        let options = {
          email_id: config.email.sendwithus.templates.registration,
          recipient: { address: this_user.email },
          email_data: {
            email_address: this_user.email,
            registration_link: config.mobile_registration_url + '/' + regToken.token1 + '/' + regToken.token2,
            contact_link: config.contact_url
          },
          sender: {
            address: config.email.sender,
            name: config.email.company
          }
        };

        email_api.send(options, (err, response) => {
          if (err) {
            req.log.error({ err });
            return next({ status: 400, message: "Unable to send registration email. " + response  });
          } else {
            return res.json({ message: "Registration email sent." });
          }
        });
      } else {
        return new Promise((resolve, reject) => {
          reject({ message: "Unable to create registration token."})
        });
      }

    })
    .catch(err => {
      next(err);
    });

}

export function retrieveRegistrationDetails(req, res, next) {
  // Validate token params against RegistrationToken.
  // get user_id
  // get User
  // get UserDetail
  // get Account/Location(?) from UserRole?
  // return user info
  // return authtoken

  let { token1, token2 } = req.params;

  let user_id = "";
  let thisUser = {};
  let thisUserDetail = {};

  let account_id = "";
  let location_id = "";
  let thisLocation = {};

  let authUser = {};
  let userAccountRoles = [];
  let userLocationRoles = [];

  registrationToken.retrieve({ token1, token2 })
    .then(resultRegToken => {

      // TODO: retrieve all User info in Batch instead of serially.

      if(!_.isEmpty(resultRegToken)) {

        user_id = resultRegToken.Item.user_id;

        // Reject if token is inactive.
        if(!resultRegToken.Item.is_active) {
          return new Promise((resolve, reject) => {
            reject({ message: "Registration token expired."})
          });
        }

        // Get User.
        return user.retrieve({ id: user_id });

      } else {
        return new Promise((resolve, reject) => {
          reject({ message: "Invalid token."})
        });
      }

    })
    .then(resultUser => {

      //console.log(resultUser);

      thisUser = filterUser(resultUser.Item);
      return userDetail.retrieve({ user_id });
    })
    .then(resultUserDetail => {

      //console.log(resultUserDetail)

      thisUserDetail = resultUserDetail.Item;
      return userAccountRole.retrieveByUserId({ user_id: thisUser.id })

    })
    // TODO: getting role info needs reformation for batch and put into util, brute forcing for now.
    .then(userAccountRoleResult => {

      //console.log(userAccountRoleResult)

      userAccountRoles = userAccountRoleResult.Items;
      return userLocationRole.retrieveByUserId({ user_id: thisUser.id })

    })
    .then(userLocationRoleResult => {

      //console.log(userLocationRoleResult)

      userLocationRoles = userLocationRoleResult.Items;

      // Start constructing user for auth payload.
      authUser = _.clone(thisUser);
      authUser.accounts = [];
      authUser.locations = [];

      // Add accounts and locations if present.
      for(let item of userAccountRoles) {
        authUser.accounts.push(item.account_id);
      }
      for(let item of userLocationRoles) {
        authUser.locations.push(item.location_id);
      }

      // NOTE: this will only get ONE Account and Location!
      account_id = extractAccountInfo(authUser);
      location_id = extractLocationInfo(authUser);

      if(account_id && location_id) {
        // Get the location details.
        return location.retrieve({ account_id, location_id });
      } else {
        return {};
      }

    })
    .then(resultLocation => {

      if(_.isEmpty(resultLocation)) {
        thisLocation = {};
      } else {
        thisLocation = resultLocation.Item;
      }

      // Construct user package + location.
      let payload = {};

      payload = {
        "email": thisUser.email,
        "firstname" : thisUserDetail.firstname ? thisUserDetail.firstname : "",
        "lastname": thisUserDetail.lastname ? thisUserDetail.lastname : "",
        "phone_mobile" : thisUserDetail.phone_mobile ? thisUserDetail.phone_mobile : "",
        "address" : thisLocation.address ? thisLocation.address : "",
        "address2" : thisLocation.address2 ? thisLocation.address2 : "",
        "city" : thisLocation.city ? thisLocation.city : "",
        "state" : thisLocation.state ? thisLocation.state : "",
        "postalcode" : thisLocation.postalcode ? thisLocation.postalcode : "",
        "timezone" : thisLocation.timezone ? thisLocation.timezone : "",
        "token1": token1,
        "token2": token2
      }

      //payload.token = createAuthResponse(authUser, req).token;

      //console.log(jwt.verify(payload.token, config.tokenSecret));
      return res.json(payload);

    })
    .catch(err => {
      next(err);
    });
}

/**
 * Saves basic registration info and validates a token.
 *
 * The User has received an email and is confirming some items and changing their password.
 * 
 * This assumes the following is already created for the User:
 *
 * User
 * UserDetail
 * UserRole
 * Account
 * Location
 *
 */
export function saveRegistration(req, res, next) {

  // TODO: field validation.

  let userValues = {};
  let userDetailValues = {};
  let locationValues = {};
  let tokenValues = {};
  let authUser = {};
  let user_id = "";

  let userFields = [
    "password"
  ];

  let userDetailFields = [
    "firstname",
    "lastname",
    "phone_mobile"
  ];

  let locationFields = [
    "address",
    "address2",
    "city",
    "state",
    "postalcode",
    "timezone"
  ];

  let tokenFields = [
    "token1",
    "token2"
  ];

  // user
  for(let field_id in userFields) {
    let field_name = userFields[field_id];
    if(req.body[field_name]) userValues[field_name] = req.body[field_name];
  }

  // user detail
  for(let field_id in userDetailFields) {
    let field_name = userDetailFields[field_id];
    if(req.body[field_name]) userDetailValues[field_name] = req.body[field_name];
  }

  // location
  for(let field_id in locationFields) {
    let field_name = locationFields[field_id];
    if(req.body[field_name]) locationValues[field_name] = req.body[field_name];
  }

  // registration token
  for(let field_id in tokenFields) {
    let field_name = tokenFields[field_id];
    if(req.body[field_name]) tokenValues[field_name] = req.body[field_name];
  }

  // Set user as 'active'.
  userValues.is_active = true;

  // Re-validate reg tokens.
  registrationToken.retrieve({ token1: tokenValues.token1, token2: tokenValues.token2 })
    .then(resultRegToken => {

      // TODO: retrieve all User info in Batch instead of serially.
      
      if(!_.isEmpty(resultRegToken)) {

        user_id = resultRegToken.Item.user_id;

        // Reject if token is inactive.
        if(!resultRegToken.Item.is_active) {
          return new Promise((resolve, reject) => {
            reject({ message: "Registration token expired."})
          });
        }

        // Patch User.
        return user.patch({ id: user_id }, userValues);

      } else {
        return new Promise((resolve, reject) => {
          reject({ message: "Invalid token."})
        });
      }

    })
    .then(userResult => {

      if(!_.isEmpty(userDetailValues)) {
        return userDetail.patch({ user_id }, userDetailValues);
      } else {
        // TODO: future - if we need to capture all actions.
        return new Promise((resolve, reject) => {
         resolve({ message: "Nothing to update for UserDetail."}) 
        });
      }
    })
    .then(userDetailResult => {
      return userUtils.retrieveUserForAuthToken(user_id);

    })
    .then(userUtilsResult => {
      authUser = userUtilsResult;

      // Extract account_id/location_id from authenticated_user which should 
      // have roles.  
      // NOTE:  Assumes there is only ONE.
      let account_id = extractAccountInfo(authUser);
      let location_id = extractLocationInfo(authUser);

      if(!_.isEmpty(locationValues) && location_id) {
        return location.patch({ account_id, location_id }, { ...locationValues, is_profile_complete: true });
      } else {
        // TODO: future - if we need to capture all actions.
        return new Promise((resolve, reject) => {
         resolve({ message: "Nothing to update for Location."})
        });
      }

    })
    .then(locationResult => {
      // Timestamp and update the registration token to be invalid.
      let reg = {
        registered_at: moment().valueOf(),
        is_active: false
      }
      return registrationToken.patch({ token1: tokenValues.token1, token2: tokenValues.token2 }, reg);
    })
    .then(registrationTokenResult => {
      return legacyAuthService.issueToken(authUser, req.headers['user-agent'], isMobileUserAgent(req));
    })
    .then(authResponse => {
      // If successful, returns auth token.
      return res.json(authResponse);
    })
    .catch(err => {
      next(err);
    });

}

export function resetPassword(req, res, next) {
  const { user_id } = req.params;
  const { old_pass, new_pass, new_pass_conf } = req.body;
  const _req = {
    body: {
      ...(req.body),
      user_id
    }
  };

  passport.authenticate('local-password-reset', (err, isSuccessful, info) => {
    if (err) {
      return next(err);
    } else if (!isSuccessful) {
      return next({ status: 400, message: info });
    } else if (new_pass !== new_pass_conf) {
      return next({ status: 400, message: 'Passwords did not match.' });
    } else if (old_pass === new_pass) {
      return next({ status: 400, message: 'New password must be different from current password.'})
    } else {
      return user.patch({ id: user_id }, { password: new_pass })
        .then(() => user_id === req.token_metadata.user_id && req.token_metadata.time_issued && userToken.patch(
          { 
            user_id, 
            time_issued: parseInt(req.token_metadata.time_issued)
          }, 
          { 
            expiration: 0 
          }
        ))
        .then(() => res.json({ pass_reset: true }))
        .catch(err => next(err));
    }
  })(_req, res, next);
}

import _ from 'lodash';
import passport from 'passport';
import { verifyPassword } from '../../util/encryption';
import UserTable from '../models/UserTable';
import { filterUser } from '../../util/httpUtil';
import { logAttempt, countFailedAttempts } from '../../util/userLoginAttempt';
import { getLockStatus, setLockStatus, LOCK_STATUS } from '../../util/userLockStatus';
import config from '../../config/config';

const LocalStrategy = require('passport-local').Strategy;
const User = new UserTable();

const userLockedError = { status: 429, message: 'Your account has been locked. Please contact support.' };

// Set the 'username'.
const strategyOptions = {
    usernameField: 'username'
};

/**
 * Retrieve user and match password.
 *
 * TODO: retrieve associated account ids + account roles.
 */
export const login = new LocalStrategy(strategyOptions, (username, password, done) => {
  const errorMessage = "Invalid username/password.";
  let thisUser;

  // Get user from DynamoDB.
  User.getUserByEmail(username)
    .then(result => {

      if(_.isEmpty(result.Items) || !result.Items[0].password) {
        // User not found.
        return done(null, null, errorMessage);
      } 

      thisUser = result.Items[0];

      return ensureUserLock(thisUser.id);
    })
    .then(() => {
      if (verifyPassword(password, thisUser.password)) {
        // User found, passwords match.
        return logAttempt(thisUser.id, true).then(() => done(null, filterUser(thisUser), null));
      } else {
        // Credentials invalid.
        return logAttempt(thisUser.id, false).then(() => done(null, null, errorMessage));
      }
      
    })
    .catch(err => {
      return done(err, null, null);
    });

});

export const passwordReset = new LocalStrategy(
  { 
    usernameField: 'user_id',
    passwordField: 'old_pass',
  }, 
  (user_id, submittedPassword, done) => {
    ensureUserLock(user_id)
      .then(() => User.retrieve({ id: user_id }))
      .then(({ Item: { password } }) => {
        if (verifyPassword(submittedPassword, password)) {
          return logAttempt(user_id, true).then(() => done(null, true, null));
        } else {
          return logAttempt(user_id, false).then(() => done(null, false, "Your current password is incorrect."));
        }
      })
      .catch(err => done(err, null, null));
  }
);

function ensureUserLock(user_id) {
  return Promise.all([
    getLockStatus(user_id),
    countFailedAttempts(user_id)
  ])
  .then(([lockStatus, numFailedAttempts]) => {
    if (lockStatus === LOCK_STATUS.LOCKED) {
      throw userLockedError;
    } else if (numFailedAttempts >= config.maxFailedLoginAttempts) {
      return setLockStatus(user_id, LOCK_STATUS.LOCKED)
        .then(() => { throw userLockedError; });
    } else {
      return true;
    }
  });
}

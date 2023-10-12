import crypto from 'crypto';
import bcrypt from 'bcrypt';
import config from '../config/config';

const saltRounds = 10; // bcrypt default

// NOTE: using this approach for simplicity, need to use superior encryption in crypto.js(?).

export function createSalt() {
  return bcrypt.genSaltSync(saltRounds);
}

export function hashPwd(salt, pwd) {
  return bcrypt.hashSync(pwd, salt);
}

export function saltAndHashPassword(clearPassword) {
  const salt = createSalt();

  return hashPwd(salt, clearPassword);
}

export function verifyPassword(password, hashedPassword) {
  return bcrypt.compareSync(password, hashedPassword);
}

export function verifyPasswordAsync(password, hashedPassword) {
  const deferred = Promise.defer();

  bcrypt.compare(password, hashedPassword, (err, result) => {
    if (err) {
      deferred.reject(err);
    } else {
      deferred.resolve(result);
    }
  });

  return deferred.promise;
}

// Create salt and hash and add to user.
export function addHashedPassword(user) {
  if(user.password) {
    let salt = createSalt();
    user.password = hashPwd(salt, user.password);
  }
  return user;
}

// Generate a random token - useful for items like reset password.
export function generateRandomToken(len) {
  len = (len > 0) ? len : 20;
  return crypto.randomBytes(len).toString('hex');
}

export function hmac(data) {
  const hmac = crypto.createHmac('sha256', new Buffer(config.encryption.hmacKey, 'base64'));

  hmac.update(data.toLowerCase());

  return hmac.digest('hex');
}
// var crypto = require('crypto'),
import crypto from 'crypto';
import config from '../config/config';

//var algorithm = 'aes-256-gcm';
//key = '3zTvzr3p67VC61jmV54rIYu1545x4TlY', // length 32
// do not use a global iv for production, generate a new one for each encryption
//iv = '60iP0h6vJoEa' // length 12

// See https://nodejs.org/api/crypto.html

export default {
    // https://nodejs.org/api/crypto.html#crypto_crypto_createcipher_algorithm_password
    encrypt: (text, password) => {
      var cipher = crypto.createCipher('aes-256-ctr', password)
      var crypted = cipher.update(text,'utf8','hex')
      crypted += cipher.final('hex');
      return crypted;
    },
    decrypt: (text, password) => {
      var decipher = crypto.createDecipher('aes-256-ctr', password)
      var dec = decipher.update(text,'hex','utf8')
      dec += decipher.final('utf8');
      return dec;
    },

    // https://nodejs.org/api/crypto.html#crypto_crypto_createcipheriv_algorithm_key_iv
    encryptWithKeyIv: (text, key, iv) => {
      var cipher = crypto.createCipheriv('aes-256-gcm', key, iv)
      var encrypted = cipher.update(text, 'utf8', 'hex')
      encrypted += cipher.final('hex');
      var tag = cipher.getAuthTag();
      return {
        content: encrypted,
        tag: tag
      };
    },
    decryptWithKeyIv: (encrypted, key, iv) => {
        var decipher = crypto.createDecipheriv('aes-256-gcm', key, iv)
        decipher.setAuthTag(encrypted.tag);
        var dec = decipher.update(encrypted.content, 'hex', 'utf8')
        dec += decipher.final('utf8');
        return dec;
    },

    encryptBuffer: (buffer, password) => {
      var cipher = crypto.createCipher('aes-256-ctr', password)
      var crypted = Buffer.concat([cipher.update(buffer), cipher.final()]);
      return crypted;
    },
    decryptBuffer: (buffer, password) => {
      var decipher = crypto.createDecipher('aes-256-ctr', password)
      var dec = Buffer.concat([decipher.update(buffer), decipher.final()]);
      return dec;
    },

    getRandomKey: (password, keylen) => {
        // https://nodejs.org/api/crypto.html#crypto_crypto_pbkdf2sync_password_salt_iterations_keylen_digest
        return crypto.pbkdf2Sync(password, 'salt', 4096, keylen, 'sha256');
    }
}

/**
 * AES Encryption/Decryption with AES-256-GCM using random Initialization Vector + Salt
 * @type {exports}
 */

import crypto from 'crypto';
import config from '../config/config';

/**
 * Encrypts text by given key
 * @param String text to encrypt
 * @param Buffer masterkey
 * @returns String encrypted text, base64 encoded
 */


var encryptionConfig = {
  // size of the generated hash
  keyLength: 32,
  // larger salt means hashed passwords are more resistant to rainbow table, but
  // you get diminishing returns pretty fast
  saltBytes: 16,
  // more iterations means an attacker has to take longer to brute force an
  // individual password, so larger is better. however, larger also means longer
  // to hash the password. tune so that hashing the password takes about a
  // second
  iterations: 10000
};

 export function encrypt (text, masterkey) {
    try
    {
        // random initialization vector
        var iv = crypto.randomBytes(12);

        // random salt
        var salt = crypto.randomBytes(64);

        // derive key using 32 byte key length
        // crypto.pbkdf2Sync(password, salt, iterations, keylen, digest)
        var key = crypto.pbkdf2Sync(masterkey, salt, encryptionConfig.iterations, encryptionConfig.keyLength, 'sha512');

        // AES 256 GCM Mode
        var cipher = crypto.createCipheriv('aes-256-gcm', key, iv);

        // encrypt the given text
        var encrypted = Buffer.concat([cipher.update(text, 'utf8'), cipher.final()]);

        // extract the auth tag
        var tag = cipher.getAuthTag();

        // generate output
        return Buffer.concat([salt, iv, encrypted, tag]).toString('base64');
    }
    catch(e){
    }

    // error
    return null;
}

/**
 * Decrypts text by given key
 * @param String base64 encoded input data
 * @param Buffer masterkey
 * @returns String decrypted (original) text
 */
export function decrypt (data, masterkey){
    try
    {
        // base64 decoding
        var bData = new Buffer(data, 'base64');

        // convert data to buffers
        var salt = bData.slice(0, 64);
        var iv = bData.slice(64, 76);
        var tag = bData.slice(76, 92);
        var text = bData.slice(92);

        // derive key using; 32 byte key length
        var key = crypto.pbkdf2Sync(masterkey, salt , encryptionConfig.iterations, encryptionConfig.keyLength, 'sha512');

        // AES 256 GCM Mode
        var decipher = crypto.createDecipheriv('aes-256-gcm', key, iv);
        decipher.setAuthTag(tag);

        // encrypt the given text
        var decrypted = decipher.update(text, 'binary', 'utf8') + decipher.final('utf8');

        return decrypted;
    }
    catch(e){
    }

    // error
    return null;
}

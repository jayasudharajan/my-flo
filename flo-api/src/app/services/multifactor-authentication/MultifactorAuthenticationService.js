import _ from 'lodash';
import UserMultifactorAuthenticationSettingTable from './UserMultifactorAuthenticationSettingTable';
import MultifactorAuthStrategy from './MultifactorAuthStrategy';
import NotFoundException from '../utils/exceptions/NotFoundException';
import InvalidOTPCodeException from './models/exceptions/InvalidOTPCodeException';
import InvalidTokenException from './models/exceptions/InvalidTokenException';
import TokenExpiredException from './models/exceptions/TokenExpiredException';
import DIFactory from  '../../../util/DIFactory';
import speakeasy from 'speakeasy';
import qrCode from 'qrcode';
import uuid from 'uuid';
import moment from 'moment';
import MultifactorAuthenticationConfig from './MultifactorAuthenticationConfig';
import MultifactorAuthenticationTokenMetadataTable from './MultifactorAuthenticationTokenMetadataTable';
import jwt from 'jsonwebtoken';

class MultifactorAuthenticationService {

  constructor(userMultifactorAuthenticationSettingTable, mfaTokenMetadataTable, mfaConfig) {
    this.userMultifactorAuthenticationSettingTable = userMultifactorAuthenticationSettingTable;
    this.mfaTokenMetadataTable = mfaTokenMetadataTable;
    this.mfaConfig = mfaConfig;
  }

  getAuthStrategy() {
    return new MultifactorAuthStrategy(this);
  }

  _getPublicUserMFASettings(data) {
   
    return data && _.pick(data, [
      'user_id',
      'secret',
      'qr_code_data_url',
      'is_enabled'
    ]);
  }

  retrieveUserMFASettings(userId) {
    return this.userMultifactorAuthenticationSettingTable.retrieve(userId)
      .then(({ Item }) => this._getPublicUserMFASettings(Item));
  }

  createUserMFASettings(userId) {
    const secret = speakeasy.generateSecret({ name: 'Flo MFA' });
    const deferred = Promise.defer();
    const encodedSecret = secret.base32;

    // Get the data URL of the authenticator URL
    qrCode.toDataURL(secret.otpauth_url, function (err, qrCodeDataUrl) {
      if (err) {
        deferred.reject(err);
      } else {
        deferred.resolve(qrCodeDataUrl);
      }
    });

    return deferred.promise
      .then(qr_code_data_url => {
        const settings = {
          user_id: userId,
          secret: encodedSecret,
          otp_auth_url: secret.otpauth_url,
          qr_code_data_url,
          is_enabled: 0,
          created_at: new Date().toISOString()
        };

        return this.userMultifactorAuthenticationSettingTable.create(settings)
          .then(() => settings);
      });
  }

  ensureUserMFASettings(userId) {
    return this.retrieveUserMFASettings(userId)
      .then(settings => settings || 
        this.createUserMFASettings(userId)
          .then(settings => this._getPublicUserMFASettings(settings))
      );
  }

  enableMFA(userId, codeToVerify) {
    return this.retrieveUserMFASettings(userId)
      .then(settings => {

        if (!settings) {
          return Promise.reject(new NotFoundException('MFA settings not found.'))
        }

        const isVerified = speakeasy.totp.verify({
          secret: settings.secret,
          encoding: 'base32',
          token: codeToVerify
        });

        if (isVerified) {
          return this.userMultifactorAuthenticationSettingTable
            .patch({ user_id: userId }, { is_enabled: 1 })
            .then(() => ({ ...settings, is_enabled: 1 }));
        } else {
          return Promise.reject(new InvalidOTPCodeException());
        }
      });
  }

  disableMFA(userId) {
    return this.retrieveUserMFASettings(userId)
      .then(settings => {

        return settings && this.userMultifactorAuthenticationSettingTable
          .patch({ user_id: userId }, { is_enabled: 0 })
          .then(() => ({ ...settings, is_enabled: 0 }));
      });
  }

  isMFAEnabled(userId) {
    return this.userMultifactorAuthenticationSettingTable.retrieve(userId)
      .then(({ Item }) => {
        return !Item ? false : Item.is_enabled == 1;
      });
  }

  issueToken(userId, tokenMetadata = {}) {

    return Promise.all([
      this.mfaConfig.getMFATokenTTL(),
      this.mfaConfig.getMFATokenSecret()
    ])
    .then(([ttl, tokenSecret]) => {
      const payload = {
        user_id: userId,
        iat: Math.floor(new Date().getTime() / 1000)
      };
      const options = {
        expiresIn: ttl,
        jwtid: uuid.v4()
      };
      const metadata = _.omitBy({ 
        ...tokenMetadata,
        user_id: payload.user_id,
        token_id: options.jwtid,
        created_at: moment.unix(payload.iat).toISOString(),
        expires_at: moment.unix(payload.iat).add(ttl, 'seconds').toISOString()
      }, _.isUndefined);
      const token = jwt.sign(payload, tokenSecret, options);

      return this.mfaTokenMetadataTable.create(metadata)
        .then(() => ({ token, metadata }));
    });
  }

  verifyToken(token) {

    return this.mfaConfig.getMFATokenSecret()
      .then(tokenSecret => {
        const deferred = Promise.defer();

        jwt.verify(token, tokenSecret, (err, decodedToken) => {
          if (err && err.name === 'TokenExpiredError') {
            deferred.reject(new TokenExpiredException());
          } else if (err) {
            deferred.reject(new InvalidTokenException());
          } else {
            deferred.resolve(decodedToken);
          }
        });

        return deferred.promise;
      })
      .then(decodedToken => {
        const { jti: token_id, user_id } = decodedToken;

        return this.mfaTokenMetadataTable.retrieve({ token_id });
      })
      .then(({ Item: tokenMetadata }) => {
        
        if (!tokenMetadata) {
          return Promise.reject(new InvalidTokenException());
        } else if (new Date() > new Date(tokenMetadata.expires_at)) {
          return Promise.reject(new TokenExpiredException());
        }

        return this.mfaTokenMetadataTable.remove({ token_id: tokenMetadata.token_id })
          .then(() => tokenMetadata);
      });
  }
}


export default new DIFactory(MultifactorAuthenticationService, [UserMultifactorAuthenticationSettingTable, MultifactorAuthenticationTokenMetadataTable, MultifactorAuthenticationConfig]);
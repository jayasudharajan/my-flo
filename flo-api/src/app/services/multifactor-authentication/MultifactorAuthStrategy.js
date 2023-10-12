import { Strategy as TotpStrategy } from 'passport-totp';
import InvalidOTPCodeException from './models/exceptions/InvalidOTPCodeException';
import base32 from 'thirty-two';

export default class MultifactorAuthStrategy extends TotpStrategy {

    constructor(mfaService) {

      super((user, done) => {
        mfaService.retrieveUserMFASettings(user.user_id)
          .then(settings => {
            if (!settings) {
              return done();
            }

            const decodedSecret = base32.decode(settings.secret);

            return done(null, decodedSecret, 30);
           
          })
          .catch(done);
      });

      this.mfaService = mfaService;
    }

    authenticate(req, options) {

      this.mfaService.verifyToken(req.body.mfa_token)
        .then(({ user_id, client_id }) => {
          req.user = { user_id, client_id };

          super.authenticate(req, options);
        })
        .catch(err => this.error(err));
    }
}
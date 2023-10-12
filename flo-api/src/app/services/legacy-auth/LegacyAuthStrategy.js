import Strategy from 'passport-strategy';

export default class LegacyAuthStrategy extends Strategy {
  constructor(legacyAuthService) {
    super();
    this.legacyAuthService = legacyAuthService;
    this.name = 'legacy';
  }

  authenticate(req) {

    this.legacyAuthService.verifyToken(req.headers.authorization || '')
      .then(tokenMetadata => {
        this.success({ user_id: tokenMetadata.user_id }, tokenMetadata);
      })
      .catch(err => {
        this.error(err);
      });
  }
}
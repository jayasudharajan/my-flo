import DIFactory from '../../../util/DIFactory';
import semver from 'semver';

class FirmwareFeaturesService {

  constructor(config) {
    this.config = config;
  }

  retrieveVersionFeatures(version) {
    const hasAwayMode = semver.gte(semver.coerce(version), '3.6.0');

    if(hasAwayMode) {
      return Promise.resolve({
        features: [{
          name: "away_mode",
          version: "2.0.0"
        }]
      });
    } else {
      return Promise.resolve({
        features: []
      });
    }
  }
}

export default new DIFactory(FirmwareFeaturesService, ['FirmwareFeaturesConfig']);
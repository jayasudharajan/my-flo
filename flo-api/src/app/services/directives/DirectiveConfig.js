import config from '../../../config/config';

export default class DirectiveConfig {
  getDirectivesKafkaTopic() {
    return Promise.resolve(config.directivesKafkaTopic);
  }
}
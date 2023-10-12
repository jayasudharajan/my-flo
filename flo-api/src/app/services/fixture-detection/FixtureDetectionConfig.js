export default class FixtureDetectionConfig {
  constructor(config) {
    this.config = config;
  }

  fixtureDetectionKafkaTopic() {
    return Promise.resolve(this.config.fixtureDetectionKafkaTopic);
  }
}
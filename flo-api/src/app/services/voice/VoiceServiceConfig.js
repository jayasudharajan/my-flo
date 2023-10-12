class VoiceServiceConfig {
  constructor(config) {
    this.config = config;
  }

  getVoiceCallOption0Audio() {
    return this.config.voiceCallOption0Audio;
  }

  getVoiceCallOption1Audio() {
    return this.config.voiceCallOption1Audio;
  }

  getVoiceCallOption2Audio() {
    return this.config.voiceCallOption2Audio;
  }

  getCustomerCarePhone() {
    return this.config.customerCarePhone;
  }

  getVoiceCallHomeWrongInputUrl(gatherUrl) {
    return this.config.voiceCallHomeWrongInputUrl + '?gather_action_url=' + gatherUrl;
  }

  getVoiceCallAwayWrongInputUrl(gatherUrl) {
    return this.config.voiceCallAwayWrongInputUrl + '?gather_action_url=' + gatherUrl;
  }
}

export default VoiceServiceConfig;


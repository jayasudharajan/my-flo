import _ from 'lodash';
import config from '../../../config/config';
import DIFactory from '../../../util/DIFactory';
import VoiceService from './VoiceService';

class VoiceController {

  constructor(httpClient, voiceService, apiHost, voiceGatherActionUrl) {
    this.httpClient = httpClient;
    this.voiceService = voiceService;
    this.apiHost = apiHost;
    this.voiceGatherActionUrl = voiceGatherActionUrl;
  }

  gatherUserAction(req, res, next) {
    const { body, params: { incident_id, user_id } } = req;

    const gatherUrl = this.voiceGatherActionUrl ?
      this.voiceGatherActionUrl.replace(':user_id', user_id).replace(':incident_id', incident_id)
        :
      'https://' + (this.apiHost || req.get('host')) + req.originalUrl;

    return this._gatherUserActionV2(user_id, incident_id, body, gatherUrl)
      .then(xml => res.type('text/xml').send(xml))
      .catch(next)
  }

  _gatherUserActionV2(userId, incidentId, data, gatherUrl) {
    return this.httpClient({
      method: 'POST',
      url: `${config.notificationApiUrl}/voice/gather/user-action/${userId}/${incidentId}`,
      headers: {
        'Content-Type': 'application/json'
      },
      data: {
        gatherUrl: gatherUrl,
        callSid: data.CallSid,
        digits: data.Digits,
        rawData: this._toLowerCamelCaseObject(data)
      }
    }).then(response => response.data)
  }

  _toLowerCamelCaseObject(obj) {
    if (_.isArray(obj)) {
      return obj.map(x => this.toLowerCamelCaseObject(x))
    } else {
      return _.mapKeys(obj, (v, k) => _.camelCase(k))
    }
  }
}

export default new DIFactory(VoiceController, [ 'HttpClient', VoiceService, 'ApiHost', 'VoiceGatherActionUrl' ]);

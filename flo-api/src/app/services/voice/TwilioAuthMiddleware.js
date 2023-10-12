const client = require('twilio');
import UnauthorizedException from '../utils/exceptions/UnauthorizedException';

class TwilioAuthMiddleware {

  constructor(config) {
    this.config = config
  }

  requiresAuth() {
    return (req, res, next) => {
      try {
        const { params: { incident_id: incidentId, user_id: userId } } = req;
        const url = this.config.voiceGatherActionUrl ?
          this.config.voiceGatherActionUrl.replace(':user_id', userId).replace(':incident_id', incidentId)
            :
          'https://' + (this.config.apiHost || req.get('host')) + req.originalUrl;

        const twilioSignature = req.get('x-twilio-signature');

        if (client.validateRequest(this.config.twilioAuthToken, twilioSignature, url, req.body)) {
          return next();
        } else {
          return next(new UnauthorizedException());
        }
      } catch (err) {
        next(err);
      }
    };
  }
}

export default TwilioAuthMiddleware;

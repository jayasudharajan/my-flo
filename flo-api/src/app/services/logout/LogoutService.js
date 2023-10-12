import DIFactory from  '../../../util/DIFactory';
import OAuth2Service from '../oauth2/OAuth2Service';
import PushNotificationTokenService from '../push-notification-token/PushNotificationTokenService';
import ServiceException from '../utils/exceptions/ServiceException';
import ClientService from '../client/ClientService';

class LogoutService {
  constructor(oauth2Service, pushNotificationTokenService, clientService) {
    this.oauth2Service = oauth2Service;
    this.pushNotificationTokenService = pushNotificationTokenService;
    this.clientService = clientService;
  }

  logout(accessTokenId, userId, clientId, mobileDeviceId) {

    if (!accessTokenId || !userId || !clientId) {
      return Promise.reject(new ServiceException('Invalid token.'));
    }

    return Promise.all([
      this.oauth2Service.revokeAccessToken(accessTokenId),
      mobileDeviceId && this.pushNotificationTokenService.disableToken(clientId, mobileDeviceId),
      clientId && this.clientService.unregisterClientUser(clientId, userId)
    ]);
  }
}

export default new DIFactory(LogoutService, [OAuth2Service, PushNotificationTokenService, ClientService]);
import LogoutService from './LogoutService'
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class LogoutController {

  constructor(logoutService) {
    this.logoutService = logoutService;
  }

  logout({ body: { mobile_device_id }, token_metadata: { token_id, user_id, client_id } }) {
    return this.logoutService.logout(token_id, user_id, client_id, mobile_device_id)
      .then(() => ({}));
  }

}

export default new DIFactory(new ControllerWrapper(LogoutController), [LogoutService]);

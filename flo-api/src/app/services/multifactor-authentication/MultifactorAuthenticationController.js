import MultifactorAuthenticationService from './MultifactorAuthenticationService';
import UserAccountService from '../user-account/UserAccountService';
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';
import { isMobileUserAgent } from '../../../util/httpUtil';
import LegacyAuthService from '../legacy-auth/LegacyAuthService';

class MultifactorAuthenticationController {
	constructor(multifactorAuthenticationService, legacyAuthService, userAccountService) {
		this.multifactorAuthenticationService = multifactorAuthenticationService;
		this.legacyAuthService = legacyAuthService;
		this.userAccountService = userAccountService;
	}

  retrieveUserMFASettings({ params: { user_id } }) {
    return this
      .multifactorAuthenticationService
      .retrieveUserMFASettings(user_id);
  }

  createUserMFASettings({ params: { user_id } }) {
    return this.multifactorAuthenticationService.createUserMFASettings(user_id);
  }

  ensureUserMFASettings({ params: { user_id } }) {
    return this.multifactorAuthenticationService.ensureUserMFASettings(user_id);
  }

  enableMFA({ params: { user_id }, body: { code } }) {

    return this
      .multifactorAuthenticationService
      .enableMFA(user_id, code);
  }

  disableMFA({ params: { user_id } })  {
    return this
      .multifactorAuthenticationService
      .disableMFA(user_id);
  }
}

export default new DIFactory(
  new ControllerWrapper(MultifactorAuthenticationController),
  [MultifactorAuthenticationService, LegacyAuthService, UserAccountService]
);
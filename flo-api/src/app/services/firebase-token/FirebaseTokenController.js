import FirebaseTokenService from './FirebaseTokenService';
import DIFactory from '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class FirebaseTokenController {
  constructor(firebaseTokenService) {
    this.firebaseTokenService = firebaseTokenService;
  }

  issueToken({ user: { user_id } }) {
    return this.firebaseTokenService.issueToken(user_id);
  }
}

export default new DIFactory(new ControllerWrapper(FirebaseTokenController), [FirebaseTokenService]);
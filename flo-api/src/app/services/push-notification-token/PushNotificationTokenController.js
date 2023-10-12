import DIFactory from  '../../../util/DIFactory';
import { CrudServiceController, ControllerWrapper } from '../../../util/controllerUtils';
import PushNotificationTokenService from './PushNotificationTokenService';
import ClientType from '../../../util/ClientType';

class PushNotificationTokenController extends CrudServiceController {
  constructor(pushNotificationService) {
    super(pushNotificationService);

    this.pushNotificationService = pushNotificationService;
  }

  retrieveByUserId({ params: { user_id } }) {
    return this.pushNotificationService.retrieveByUserId(user_id);
  }

  registerIOSToken({ body: { mobile_device_id, aws_endpoint_id, token }, token_metadata: { user_id, client_id } }) {
    return this.pushNotificationService.create({ 
      mobile_device_id,
      aws_endpoint_id,
      client_id,
      user_id,
      token,
      client_type: ClientType.IPHONE
    });
  }

  registerAndroidToken({ body: { mobile_device_id, aws_endpoint_id, token }, token_metadata: { user_id, client_id } }) {
    return this.pushNotificationService.create({ 
      mobile_device_id,
      aws_endpoint_id,
      client_id,
      user_id,
      token,
      client_type: ClientType.ANDROID_PHONE
    });
  }
}

export default new DIFactory(ControllerWrapper(PushNotificationTokenController), [PushNotificationTokenService]);
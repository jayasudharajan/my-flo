import CrudService from '../utils/CrudService';
import PushNotificationTokenTable from './PushNotificationTokenTable';
import DIFactory from  '../../../util/DIFactory';

class PushNotificationTokenService extends CrudService {
  constructor(pushNotificationTokenTable) {
    super(pushNotificationTokenTable);

    this.pushNotificationTokenTable = pushNotificationTokenTable;
  }

  retrieveByUserId(userId) {
    return this.pushNotificationTokenTable.retrieveByUserId(userId)
      .then(({ Items }) => Items);
  }

  disableToken(clientId, mobileDeviceId) {
    return this.pushNotificationTokenTable.patch({ client_id: clientId, mobile_device_id: mobileDeviceId }, { is_disabled: 1 });
  }
}

export default new DIFactory(PushNotificationTokenService, [PushNotificationTokenTable]);

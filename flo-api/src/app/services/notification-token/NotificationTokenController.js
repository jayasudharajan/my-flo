import NotificationTokenService from './NotificationTokenService';
import { CrudController, ControllerWrapper } from '../../../util/controllerUtils';
import DIFactory from '../../../util/DIFactory';

class NotificationTokenController extends CrudController {

	constructor(notificationTokenService) {
		super(notificationTokenService.notificationTokenTable);

		this.notificationTokenService = notificationTokenService;
	}

	addToken({ params: { user_id }, body: { token, deviceType } }) {
		return this.notificationTokenService.notificationTokenTable.addToken(user_id, token, deviceType);
	}

	removeToken({ params: { user_id }, body: { token } }) {
		return this.notificationTokenService.notificationTokenTable.removeToken(user_id, token);
	}
}

export default new DIFactory(new ControllerWrapper(NotificationTokenController), [NotificationTokenService]);
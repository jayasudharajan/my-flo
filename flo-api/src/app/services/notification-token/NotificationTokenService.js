import UserTokenTable from '../../models/UserTokenTable';
import NotificationTokenTable from './NotificationTokenTable';
import DIFactory from  '../../../util/DIFactory';

const userTokenTable = new UserTokenTable();

class NotificationTokenService {

	constructor(notificationTokenTable, userTokenTable) {
		this.notificationTokenTable = notificationTokenTable;
		this.userTokenTable = userTokenTable;
	} 

}

export default new DIFactory(NotificationTokenService, [NotificationTokenTable, UserTokenTable]);


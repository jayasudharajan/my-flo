import DIFactory from  '../../../util/DIFactory';
import UsersIndex from './UsersIndex';
import ICDsIndex from './ICDsIndex';
import ActivityLogIndex from './ActivityLogIndex';

class InfoService {
	constructor(usersIndex, icdsIndex, activityLogIndex) {
		this.users = usersIndex;
		this.icds = icdsIndex;
    this.activityLogIndex = activityLogIndex;
	}

  retrieveDevicesLeakStatus(startDate, endDate, leakStatusFilters, subscriptionFilters, size = 20, page = 1) {
    return this.activityLogIndex.getDeviceLeakStatuses(startDate, endDate, leakStatusFilters, subscriptionFilters, page, size);
  }

  retrieveLeakStatusCounts(startDate, endDate) {
    return this.activityLogIndex.getLeakStatusCounts(startDate, endDate);
  }
}


export default DIFactory(InfoService, [UsersIndex, ICDsIndex, ActivityLogIndex]);
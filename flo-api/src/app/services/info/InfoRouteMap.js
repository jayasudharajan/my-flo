export default class InfoRouteMap {
	constructor() {
		this.retrieveAllUsers = [
			{ get: '/users' },
			{ post: '/users' }
		];

		this.retrieveUserByUserId = { 
			get: '/users/:user_id' 
		};

		this.retrieveAllICDs = [
			{ get: '/devices' },
			{ post: '/devices' }
		];

		this.retrieveAllICDsWithScroll = [
			{ post: '/devices/scroll' }
		];

		this.scrollAllICDs = [
			{ post: '/devices/scroll/:scroll_id' }
		];

		this.retrieveICDByICDId = {
			get: '/devices/:icd_id'
		};

		this.retrieveGroupUserByUserId = {
			get: '/group/:group_id/users/:user_id'
		};

		this.retrieveGroupICDByICDId = {
			get: '/group/:group_id/devices/:icd_id'
		};

		this.retrieveAllGroupUsers = [
			{ get: '/group/:group_id/users' },
			{ post: '/group/:group_id/users' }
		];

		this.retrieveAllGroupICDs = [
			{ get: '/group/:group_id/devices' },
			{ post: '/group/:group_id/devices' }
		];

		this.aggregateICDsByOnboardingEvent = [
			{ get: '/onboarding' },
			{ post: '/onboarding' }
		];

		this.retrieveDevicesLeakStatus = [
			{ post: '/devices/dailyleaktestresults' }
		];

		this.retrieveLeakStatusCounts = [
			{ post: '/devices/dailyleaktestresults/count' }
		];
	}
}
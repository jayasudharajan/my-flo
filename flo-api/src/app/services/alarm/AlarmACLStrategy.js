export default class AlarmACLStrategy {
	constructor(aclMiddleware) {
		this.retrieveByICDId = aclMiddleware.requiresPermissions([{
			resource: 'Alarm',
			permission: 'retrieveByICDId'
		}]);

		this.retrieveByIncidentId = aclMiddleware.requiresPermissions([{
			resource: 'Alarm',
			permission: 'retrieveByIncidentId'
		}]);

		this.retrieveDeliveryAnalytics = aclMiddleware.requiresPermissions([{
			resource: 'Alarm',
			permission: 'retrieveDeliveryAnalytics'
		}])
	}
}
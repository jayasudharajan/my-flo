export default class MicroLeakTestTimeACLStrategy {
	constructor(aclMiddleware) {
		this.deployTimesConfig = aclMiddleware.requiresPermissions([
			{
				resource: 'ICD',
				permission: 'deployMicroleakTestTimeConfig'
			}
		]);

		this.retrievePendingTimesConfig = aclMiddleware.requiresPermissions([
			{
				resource: 'ICD',
				permission: 'retrievePendingMicroleakTestTimeConfig'
			}
		]);
	}
}
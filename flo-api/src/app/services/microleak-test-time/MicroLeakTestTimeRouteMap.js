export default class MicroLeakTestTimeRouteMap {
	constructor() {
		this.deployTimesConfig = [
			{ post: '/deploy/configs/:device_id' }
		];
		this.retrievePendingTimesConfig = [
			{ get: '/pending/configs' }
		];
	}
}
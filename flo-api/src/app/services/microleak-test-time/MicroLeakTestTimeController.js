import MicroLeakTestTimeService from './MicroLeakTestTimeService'
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class MicroLeakTestTimeController {
	constructor(mlttcService) {
		this.mlttcService = mlttcService;
	}

	deployTimesConfig({ params: { device_id, user_id }, app_used, body }) {
		return this.mlttcService.deployTimesConfig(device_id, body, user_id, app_used);
	}
	retrievePendingTimesConfig() {
		return this.mlttcService.retrievePendingTimesConfig();
	}
}

export default new DIFactory(new ControllerWrapper(MicroLeakTestTimeController), [MicroLeakTestTimeService]);
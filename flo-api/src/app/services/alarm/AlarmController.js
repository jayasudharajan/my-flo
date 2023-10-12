import AlarmService from './AlarmService';
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class AlarmController {
	constructor(alarmService) {
		this.alarmService = alarmService;
	}

	retrieveByICDId({ 
		query: { size, page, start, end }, 
		params: { icd_id }, 
		body: { filter } 
	}) {
		const options = { size,	page, filter };		

		return this.alarmService.retrieveByICDId(icd_id, start && parseInt(start), end && parseInt(end), options);
	}

	retrieveByIncidentId({ query: { start, end }, params: { incident_id } }) {
		return this.alarmService.retrieveByIncidentId(incident_id, start && parseInt(start), end && parseInt(end));
	}

	retrieveDeliveryAnalytics({ query: { start, end }, body: { filter = {} } }) {
		return this.alarmService.retrieveDeliveryAnalytics(parseInt(start), parseInt(end), filter);
	}
}

export default new DIFactory(new ControllerWrapper(AlarmController), [AlarmService]);
import moment from 'moment';
import _ from 'lodash';
import ICDAlarmIncidentRegistriesIndex from './ICDAlarmIncidentRegistriesIndex';
import ICDAlarmIncidentRegistryLogsIndex from './ICDAlarmIncidentRegistryLogsIndex';
import DIFactory from  '../../../util/DIFactory';

class AlarmService {
	constructor(icdAlarmIncidentRegistriesIndex, icdAlarmIncidentRegistryLogsIndex) {
		this.icdAlarmIncidentRegistriesIndex = icdAlarmIncidentRegistriesIndex;
		this.icdAlarmIncidentRegistryLogsIndex = icdAlarmIncidentRegistryLogsIndex;
	}

	retrieveByICDId(icdId, _startDate, _endDate, options) {
		const { startDate, endDate } = getDateRange(_startDate, _endDate);

		return this.icdAlarmIncidentRegistriesIndex.retrieveAll(
			startDate,
			endDate,
			_.merge(
				{}, 
				options, 
				{ 
					filter: { 
						'icd_data.id': icdId,
						incident_time: {
							gte: startDate.toISOString(),
							lte: endDate.toISOString()
						}
					},
					sort: [{ incident_time: 'desc' }]
				}
			)
		);
	}

	retrieveByIncidentId(incidentId, _startDate, _endDate) {
		const { startDate, endDate } = getDateRange(_startDate, _endDate);

		return this.icdAlarmIncidentRegistriesIndex.retrieveAll(
			startDate,
			endDate,
			{ 
				filter: { id: incidentId },
				range: {
					incident_time: {
						gte: startDate.toISOString(),
						lte: endDate.toISOString()
					}
				}
			}
		);
	}

	retrieveDeliveryAnalytics(_startDate, _endDate, filter) {
		const { startDate, endDate } = getDateRange(_startDate, _endDate);

		return this.icdAlarmIncidentRegistryLogsIndex.retrieveAnalytics(startDate, endDate, filter);
	}
}

function getDateRange(_startDate, _endDate) {
	const endDate = _endDate ? moment(_endDate) : moment().endOf('month');
	const startDate = _startDate ? moment(_startDate) : moment(endDate).startOf('month');

	return { startDate, endDate };
}

export default new DIFactory(AlarmService, [ICDAlarmIncidentRegistriesIndex, ICDAlarmIncidentRegistryLogsIndex]);
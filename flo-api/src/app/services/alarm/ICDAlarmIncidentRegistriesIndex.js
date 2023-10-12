import elasticsearch from 'elasticsearch';
import ElasticsearchMonthlyLogIndex from '../utils/ElasticsearchMonthlyLogIndex';
import DIFactory from  '../../../util/DIFactory';

class ICDAlarmIncidentRegistriesIndex extends ElasticsearchMonthlyLogIndex {
	constructor(elasticsearchClient) {
		super('icdalarmincidentregistries', elasticsearchClient);
	}
}

export default new DIFactory(ICDAlarmIncidentRegistriesIndex, [elasticsearch.Client]);
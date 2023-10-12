import elasticsearch from 'elasticsearch';
import ElasticsearchMonthlyLogIndex from '../utils/ElasticsearchMonthlyLogIndex';
import DIFactory from  '../../../util/DIFactory';

class ICDAlarmIncidentRegistryLogsIndex extends ElasticsearchMonthlyLogIndex {
	constructor(elasticsearchClient) {
		super('icdalarmincidentregistrylogs', elasticsearchClient);
	}

	retrieveAnalytics(startDate, endDate, filter) {
		
		return this.elasticsearchClient.search({
			index: this._getIndexNames(startDate, endDate),
			size: 0,
			body: {
				query: this._createQuery({ filter }),
				aggs: {
					delivery_media: {
						terms: {
							field: 'delivery_medium'
						},
						aggs: {
							unique_incidents: {
								cardinality: {
									field: 'icd_alarm_incident_registry_id',
									precision_threshold: 4000
								}
							},
							triggered: {
								filter: {
									term: { status: 2 }
								}
							}
						}
					}
				}
			}
		})
		.then(result => {
			const deliveryMedia = (((result.aggregations || {}).delivery_media || {}).buckets || [])
				.map(({ key, triggered = {}, unique_incidents = {} }) => ({
					delivery_medium: key,
					total_triggered: triggered.doc_count || 0,
					total_unique_incidents: unique_incidents.value || 0
				}));

			return {
				aggregations: {
					delivery_mediums: deliveryMedia
				}
			};
		});
	}
}

export default new DIFactory(ICDAlarmIncidentRegistryLogsIndex, [elasticsearch.Client]);
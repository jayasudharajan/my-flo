import _ from 'lodash';
import elasticsearch from 'elasticsearch';
import ElasticsearchIndex from '../utils/ElasticsearchIndex';
import DIFactory from  '../../../util/DIFactory';

class ICDsIndex extends ElasticsearchIndex {
	constructor(elasticsearchClient) {
		super('icds', elasticsearchClient);
	}

	retrieveByICDId(icdId) {

		return this.retrieve('icd', icdId);
	}

	_createQuery({ query, filter }) {
		const esQuery = super._createQuery({ query, filter });
		const validDeviceFilter = [
			{
				exists: {
					field: 'device_id'
				}
			},
			{
				exists: {
					field: 'geo_location'
				}
			},
			{
				exists: {
					field: 'owner_user_id'
				}
			},
			{
			 nested: {
			 		path: 'users',
			 		query: {
			 			bool: {
			 				filter: {
			 					exists: {
			 						field: 'users'
			 					}
			 				}
			 			}
			 		}
			 }
			}
		];

		return {
			bool: {
				..._.get(esQuery, 'bool', {}),
				filter: [
					..._.get(esQuery, 'bool.filter', []),
					...validDeviceFilter
				]
			}
		};
	}

	_createMatchQuery(query) {
		return {
			minimum_should_match: 1,
			should: [
				{
					match: {
						'device_id.analyzed': {
							query,
							operator: 'and'
						}
					}
				},
				{
					nested: {
						path: 'users',
						query: {
							multi_match: {
								query,
								type: 'cross_fields',
								fields: [
									'users.firstname', 
									'users.lastname',
									'users.email'
								],
								operator: 'and'
							}
						}
					}
				}
			]
		};
	}

	aggregateByOnboardingEvent({ startDate = new Date(0).getTime(), endDate = new Date().getTime() }, options = {}) {
		const { filter, query: queryString } = this._processOptions(options);
		const query = _.isEmpty(filter) && _.isEmpty(queryString) ?
			{} :
			{ query: this._createQuery({ filter, query: queryString }) };
		const aggregations = {
			onboarding_events: {
				nested: {
					path: 'onboarding'
				},
				aggs: {
					event_types: {
						terms: {
							field: 'onboarding.event',
							order: { _term: 'asc' }
						},
						aggs: {
							date_range: {
								filter: {
									range: {
										'onboarding.created_at': {
											gte: new Date(startDate).toISOString(),
											lte: new Date(endDate).toISOString()
										}
									}
								},
								aggs: {
									icds: {
										reverse_nested: {}
									}
								}
							}
						}
					}
				}
			}
		};

		return this.elasticsearchClient.search({
			index: this.indexName,
			size: 0,
			body: {
				...query,
				aggregations
			}
		})
		.then(result => {
			const onboardingEvents = result.aggregations.onboarding_events.event_types.buckets
				.map(({ key, date_range: { icds: { doc_count } } }) => ({
					event: key,
					total: doc_count
				}));

			return {
				total: _.sumBy(onboardingEvents, 'total'),
				aggregations: {
					onboarding_events: onboardingEvents
				}
			};
		});
	}
}

export default DIFactory(ICDsIndex, [elasticsearch.Client]);
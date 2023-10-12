import _ from 'lodash';
import moment from 'moment';
import { client as esClient } from '../../../util/elasticSearchProxy';
import { getLogIndicesNamesByDateRange, makeSearchResponse } from '../../../util/elasticSearchHelper';
import { createFilterQuery } from '../utils/ElasticsearchIndex';

export function getFullActivityLog(icd_id, { size, page, filter }) {
	return esClient.search({
		index: getIndices(),
		type: 'alert',
		size: calcSize(size),
		from: calcPage(size, page),
		body: {
			sort: [
				{ incident_time: { order: 'desc' } }
			],
			query: createICDAlertQuery({ icd_id, filter })
		}
	})
	.then(createResponse);
}

export function getPendingAlerts(icd_id, { size, page, filter }) {

  return esClient.search({
    index: getIndices(),
    type: 'alert',
    size: calcSize(size),
    from: calcPage(size, page),
    body: {
      sort: [
        { incident_time: { order: 'desc' } }
      ],
      query: createICDAlertQuery({ 
      	icd_id, 
      	filter: {
 		    system_mode: [2, 3, 4], 
      		...filter,
      		is_cleared: false,
      	} 
      })
    }
  })
  .then(createResponse);

}

export function getClearedAlerts(icd_id, { size, page, filter }) {

  return esClient.search({
    index: getIndices(),
    type: 'alert',
    size: calcSize(size),
    from: calcPage(size, page),
    body: {
       sort: [
        { incident_time: { order: 'desc' } }
      ],
      query: createICDAlertQuery({ 
      	icd_id, 
      	filter: {
    	    system_mode: [2, 3, 4], 
      		...filter,
      		is_cleared: true
      	}
      })
    }
  })
  .then(createResponse);

}

export function getAlertsBySeverity(icd_id, { size, page, filter }) {

	return esClient.search({
		index: getIndices(),
		type: 'alert',
		size: 0,
		body: {
			query: createICDAlertQuery({ 
				icd_id, 
				filter: {
		 		    system_mode: [2, 3, 4], 
					...filter,
					is_cleared: false
				}
			}),
			aggs: {
				severities: {
					terms: { 
						field: 'severity',
						order: { '_term': 'asc' } 
					},
					aggs: {
						alerts: {
							top_hits: {
								sort: [{ incident_time: 'desc' }],
								size: calcSize(size),
								from: calcPage(size, page)
							}
						}
					}
				}
			}
		}
	})
  	.then(result => ({
  		total: result.hits.total,
  		aggregations: ((result.aggregations.severities || {}).buckets || [])
  			.map(({ key, alerts: { hits: { total, hits } } }) => ({
  				total,
  				severity: key,
  				alerts: hits.map(({ _source }) => _source)
  			}))
  	}));
}

export function getAlertsByAlarmIdSystemMode(icd_id, { size, page, filter }) {
	return esClient.search({
		index: getIndices(),
		type: 'alert',
		size: 0,
		body: {
			query: createICDAlertQuery({ 
				icd_id, 
				filter: {
		 		    system_mode: [2, 3, 4], 
					...filter,
					is_cleared: false
				}
			}),
			aggs: {
				alarm_ids: {
					terms: {
						field: 'alarm_id',
						order: {
							latest_by_alarm_id: 'desc'
						}
					},
					aggs: {
						system_mode: {
							terms: {
								field: 'system_mode',
								order: {
									latest_by_system_mode: 'desc'
								}
							},
							aggs: {
								alerts: {
									top_hits: {
										sort: [{ incident_time: 'desc' }],
										size: calcSize(size),
										from: calcPage(size, page)
									}
								},
								latest_by_system_mode: {
									max: {
										field: 'incident_time'
									}
								}
							}
						},
						latest_by_alarm_id: {
							max: {
								field: 'incident_time'
							}
						}
					}
				}
			}
		}
	})
	.then(result => ({
		total: result.hits.total,
		aggregations: ((result.aggregations.alarm_ids || {}).buckets || [])
			.map(({ key, system_mode }) => {
				const system_modes = (system_mode.buckets || [])
					.map(({ key, alerts: { hits: { total, hits } } }) => ({
						system_mode: key,
						total,
						alerts: hits.map(({ _source }) => _source)
					}));

				return {
					alarm_id: key,
					total: _.sumBy(system_modes, 'total'),
					system_modes
				};
			})
	}));
}

export function getAlertsBySeverityAndAlarmIdSystemMode(icd_id, { size, page, filter }) {
	return esClient.search({
		index: getIndices(),
		type: 'alert',
		size: 0,
		body: {
			query: createICDAlertQuery({ 
				icd_id,
				filter: {
					system_mode: [2, 3, 4],
					...filter,
					is_cleared: false,
				}
			}),
			aggs: {
				severities: {
					terms: {
						field: 'severity', 
						order: { '_term': 'asc' }
					},
					aggs: {
						alarm_ids: {
							terms: {
								field: 'alarm_id',
								order: {
									latest_by_alarm_id: 'desc'
								}
							},
							aggs: {
								system_modes: {
									terms: {
										field: 'system_mode',
										order: {
											latest_by_system_mode: 'desc'
										}
									},
									aggs: {
										alerts: {
											top_hits: {
												sort: [{ incident_time: 'desc' }],
												size: calcSize(size),
												from: calcPage(size, page)
											}
										},
										latest_by_system_mode: {
											max: {
												field: 'incident_time'
											}
										}
									}
								},
								latest_by_alarm_id: {
									max: {
										field: 'incident_time'
									}
								}
							}
						}
					}
				}
			}
		}
	})
	.then(result => ({
		total: result.hits.total,
		aggregations: ((result.aggregations.severities || {}).buckets || [])
			.map(({ key, alarm_ids }) => {
				const alarmIds = alarm_ids.buckets
					.map(({ key, system_modes }) => {
						const systemModes = (system_modes.buckets || [])
							.map(({ key, alerts: { hits: { total, hits } } }) => ({
								system_mode: key,
								total,
								alerts: hits.map(({ _source }) => _source)
							}));

						return {
							alarm_id: key,
							total: _.sumBy(systemModes, 'total'),
							system_modes: systemModes
						};
					});

				return {
					severity: key,
					total: _.sumBy(alarmIds, 'total'),
					alarm_ids: alarmIds
				};
		})
	}));
}

export function getAnalytics({ size, page, filter }) {
	return esClient.search({
		index: getIndices(),
		type: 'alert',
		size: 0,
		body: {
			query: !filter ? {} : createFilterQuery(filter),
			aggs: {
				alarm_id_system_modes: {
					terms: {
						field: 'alarm_id_system_mode',
						size: calcSize(size),
						from: calcPage(size, page)
					},
					aggs: {
						cleared: {
							filter: {
								term: { is_cleared: true }
							},
							aggs: {
								user_actions_taken: {
									terms: {
										field: 'user_action_taken.action_id'
									}
								},
								self_resolved: {
									filter: {
										term: { self_resolved: 1 }
									}
								},
								filter_statuses: {
									terms: {
										field: 'status'
									}
								}
							}
						},
						alerts: {
							top_hits: {
								sort: [{ incident_time: 'desc' }],
								size: 1
							}
						}
					}
				}
			}
		}
	})
	.then(result => {
		return {
			total: result.hits.total,
			aggregations: {
				alarm_id_system_modes: ((result.aggregations.alarm_id_system_modes || {}).buckets || [])
					.map(({ key, doc_count, alerts = {}, cleared = {} }) => {
						const numCleared = cleared.doc_count || 0;
						const sampleAlert = (((alerts.hits || {}).hits || [])[0] || {})['_source'] || {};
						const friendlyName = sampleAlert.friendly_name || '';
						const actionDisplay = ((sampleAlert.user_actions || {}).actions || [])
							.reduce((acc, { id, display }) => ({ ...acc, [id]: display }), {});

						return {
							alarm_id_system_mode: key,
							alarm_id: sampleAlert.alarm_id,
							system_mode: sampleAlert.system_mode,
							friendly_name: friendlyName,
							total: doc_count,
							total_pending: doc_count - numCleared,
							total_cleared: numCleared,
							total_self_resolved: (cleared.self_resolved || {}).doc_count || 0,
							user_actions_taken: ((cleared.user_actions_taken || {}).buckets || [])
								.map(({ key, doc_count }) => ({ 
									action_id: key, 
									display: actionDisplay[key],
									total: doc_count 
								})),
							cleared_filter_statuses: ((cleared.filter_statuses || {}).buckets || [])
								.map(({ key, doc_count }) => ({ status: key, total: doc_count }))
						};
					})
			}
		};
	});
}

// For ALD Group Admin Dashboard
export function getAlertsByLocation(filter) {
	return esClient.search({
		index: 'icds',
		type: 'icd',
		size: 0,
		body: {
			query: createFilterQuery({
				...filter,
			}),
			aggs: {
				pending_alerts: {
					nested: {
						path: 'pending_alerts'
					},
					aggs: {
						critical_warn: {
							filter: {
								terms: {
									'pending_alerts.severity': [1, 2]
								}
							},
							aggs: {
								total_locations: {
									reverse_nested: {},
									aggs: {
										locations: {
											cardinality: {
												field: 'geo_location.location_id'
											}
										}
									}
								},
								severities: {
									terms: {
										field: 'pending_alerts.severity'
									},
									aggs: {
										icds: {
											reverse_nested: {},
											aggs: {
												locations: {
													cardinality: {
														field: 'geo_location.location_id'
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	})
	.then(result => {
		const aggregations = result.aggregations.pending_alerts.critical_warn.severities.buckets
			.map(({ key, icds: { locations } }) => ({
				severity: key,
				total_locations: locations.value
			}));

		return {
			total: result.hits.total,
			total_healthy_locations: result.hits.total - result.aggregations.pending_alerts.critical_warn.total_locations.locations.value,
			aggregations
		};
	});
}

export function getDailyLeakTestResult(beginDate, endDate) {
	return Promise.all([
		_getDailyLeakTestResult(beginDate, endDate),
		getDeviceCount(endDate)
	])
	.then(([dailyLeakTestResult, deviceCount]) => {
		const unknown = deviceCount - _.chain(dailyLeakTestResult).map(value => value || 0).sum().value();

		return {
			aggregations: {
				daily_leak_test_results: {
					unknown,
					total_installed: deviceCount,
					...dailyLeakTestResult
				}
			}
		};
	});
}

function _getDailyLeakTestResult(beginDate, endDate) {
	const mapScript = `
		String icd_id = doc['icd_id'].value; 
		long alarm_id = doc['alarm_id'].value;
		boolean has_leak = alarm_id != 5 && alarm_id != 34;

		if (params._agg.devices.containsKey(icd_id)) { 
		  params._agg.devices[icd_id] = params._agg.devices[icd_id] || has_leak;
		} else {
		  params._agg.devices[icd_id] = has_leak;
		}
	`.trim().replace(/\s+/g, ' ');
	const reduceScript = `
		Map devices = [:];
		String icd_id;
		boolean has_leak;
		Map hist = ['leak': 0, 'no_leak': 0];

		for (agg in params._aggs) {
			for (device in agg.devices.entrySet()) {
				icd_id = device.getKey();
				has_leak = device.getValue();

				if (devices.containsKey(icd_id)) {
					devices[icd_id] = devices[icd_id] || has_leak;
				} else {
					devices[icd_id] = has_leak;
				}
			}
		}

		for (device in devices.entrySet()) {
			hist[device.getValue() ? 'leak' : 'no_leak'] += 1;
		}

		return hist;
	`.trim().replace(/\s+/g, ' ');

	return esClient.search({
		index: getIndices(),
		type: 'alert',
		size: 0,
		body: {
			query: createFilterQuery({
				incident_time: {
					gte: beginDate,
					lte: endDate
				},
				alarm_id: [5, 34, 28, 29, 30, 31]
			}),
			aggs: {
				daily_leak_test_results: {
					scripted_metric: {
						init_script: 'params._agg.devices = [:];',
						map_script: mapScript,
						reduce_script: reduceScript
					}
				}
			}
		}
	})
	.then(result => {
		return result.aggregations.daily_leak_test_results.value;
	});
}

function getDeviceCount(endDate) {

	return esClient.search({
		index: 'icds',
		type: 'icd',
		size: 0,
		body: {
			query: createFilterQuery({
				'[onboarding.event]': {
					gte: 2
				},
				'[onboarding.created_at]': {
					lte: endDate
				}
			}),
			aggs: {
				installed_devices: {
					nested: {
						path: 'onboarding'
					},
					aggs: {
						installed_as_of_date: {
							filter: {
								range: {
									'onboarding.created_at': {
										lte: endDate
									}
								}
							},
							aggs: {
								installed_event: {
									filter: {
										range: {
											'onboarding.event': {
												gte: 2
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
			}
		}
	})
	.then(result => {
		return result.aggregations
			.installed_devices
			.installed_as_of_date
			.installed_event
			.icds.doc_count;
	});
}

export function getDailyAlertCount(filter, timezone = 'Etc/UTC') {

	return esClient.search({
		index: getIndices(),
		type: 'alert',
		size: 0,
		body: {
			query: createFilterQuery({
				...filter,
				severity: [1,2]
			}),
			aggs: {
				dates: {
					date_histogram: {
						field: 'incident_time',
						interval: 'day',
						time_zone: timezone
					},
					aggs: {
						severities: {
							terms: {
								field: 'severity'
							}
						}
					}
				}
			}
		}
	})
	.then(results => ({
		aggregations: {
			severity_count_by_date: results.aggregations.dates.buckets
				.map(({ key_as_string, severities: { buckets } }) => ({
					date: key_as_string,
					total_warning: (_.find(buckets, { key: 2 }) || {}).doc_count || 0,
					total_critical: (_.find(buckets, { key: 1 }) || {}).doc_count || 0
				}))
			}
	}));
}

function getIndices() {
	const now = moment().toISOString();
	const startDate = moment(now).subtract(30, 'days').startOf('day').toISOString();
	
	return getLogIndicesNamesByDateRange(startDate, now, 'alerts');
}

function calcPage(size, page) {
	return !page ? undefined : (page - 1) * (size != 0 && !size ? 10 : size);
}

function calcSize(size) {
	return size != 0 && !size ? undefined : size;
}

function createResponse(result) {
	const response = makeSearchResponse(result);

    return {
      ...response,
      items: response.items.map(item => _.omit(item, ['account', 'geo_location']))    	
    };
}

function createICDAlertQuery({ icd_id, filter }) {


	return createFilterQuery({ ...filter, icd_id });
}


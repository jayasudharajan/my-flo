import _ from 'lodash';
import elasticsearch from 'elasticsearch';
import ElasticsearchMonthlyLogIndex from '../utils/ElasticsearchMonthlyLogIndex';
import DIFactory from  '../../../util/DIFactory';

const HAS_LEAK_ALARM_IDS = [28, 29, 30, 31];
const NO_LEAK_ALARM_IDS = [5, 34];
const INTERRUPTED_ALARM_IDS = [32, 39, 40, 41];
const SKIPPED_ALARM_IDS = [4, 56];
const DELAYED_ALARM_IDS = [3, 42];
const ALL_ZIT_ALARM_IDS = [
  ...HAS_LEAK_ALARM_IDS,
  ...NO_LEAK_ALARM_IDS,
  ...INTERRUPTED_ALARM_IDS,
  ...DELAYED_ALARM_IDS,
  ...SKIPPED_ALARM_IDS
];

class ActivityLogIndex extends ElasticsearchMonthlyLogIndex {

  constructor(elasticsearchClient) {
    super('activity-log', elasticsearchClient);
  }

  getLeakStatusCounts(startDate, endDate) {
    const mostRecentMonthlyIndex = this._getIndexName(startDate, endDate);
    const onboardingQuery = this._buildOnboardingQuery(endDate);
    const testDeviceQuery = this._buildTestDeviceQuery();
    const buildLeakStatusQuery = filters => this._buildLeakStatusQuery(startDate, endDate, filters);
    const hasLeakQuery = buildLeakStatusQuery(['has_leak']);
    const noLeakQuery = buildLeakStatusQuery(['no_leak']);
    const delayedInterruptedQuery = buildLeakStatusQuery(['delayed', 'interrupted']);
    const skippedQuery = buildLeakStatusQuery(['skipped']);
    const unknownQuery = buildLeakStatusQuery(['unknown']);
    const multiSearchBody = _.chain([hasLeakQuery, noLeakQuery, delayedInterruptedQuery, skippedQuery, unknownQuery, null])
      .map(query => [
        {
          index: mostRecentMonthlyIndex,
          type: 'icd',
          size: 0
        },
        {
          query: {
            bool: {
              filter: [query, onboardingQuery, testDeviceQuery].filter(query => !_.isEmpty(query))
            }
          }
        }
      ])
      .flatten()
      .value();

    return this.elasticsearchClient.msearch({ body: multiSearchBody })
      .then(({ responses }) => 
        _.zip(
          ['has_leak', 'no_leak', 'delayed_interrupted', 'skipped', 'unknown', 'total_installed'], 
          responses.map(({ hits: { total } }) => total)
        )
        .reduce((acc, [leakStatus, total]) => ({
          ...acc,
          [leakStatus]: total
        }), {})
      );
  }

  getDeviceLeakStatuses(startDate, endDate, leakStatusFilters, subscriptionFilters, page = 1, size = 20) {
    const mostRecentMonthlyIndex = this._getIndexName(startDate, endDate);
    const leakStatusQuery = this._buildLeakStatusQuery(startDate, endDate, leakStatusFilters || undefined);
    const onboardingQuery = this._buildOnboardingQuery(endDate);
    const subscriptionQuery = !_.isEmpty(subscriptionFilters) && this._buildSubscriptionQuery(subscriptionFilters);
    const testDeviceQuery = this._buildTestDeviceQuery();

    return this._queryMonthlyIndex(
      size, 
      page, 
      mostRecentMonthlyIndex, 
      [
        leakStatusQuery, 
        onboardingQuery,
        subscriptionQuery,
        testDeviceQuery
      ]
    );
  }

  _getIndexName(startDate, endDate) {
    const indices = this._getIndexNames(startDate, endDate);

    return indices[indices.length - 1];
  }

  _buildHasChildWithAlarmIdsQuery(startDate, endDate, alarmIds, name) {
    const dateRange = {
      range: {
        incident_time: {
          gte: startDate,
          lte: endDate
        }
      }
    };

    return {
      has_child: {
        type: 'alert',
        query: {
          bool: {
            filter: [
              {
                terms: {
                  alarm_id: alarmIds
                }
              },
              dateRange
            ]
          }
        },
        _name: name
      }
    };
  }

  _buildLeakStatusQuery(startDate, endDate, leakStatusFilters = ['has_leak', 'no_leak', 'interrupted', 'delayed', 'skipped', 'unknown']) {
    const buildHasChildQuery = (name, alarmIds) => this._buildHasChildWithAlarmIdsQuery(startDate, endDate, name, alarmIds);
    const hasLeakQuery =  buildHasChildQuery(HAS_LEAK_ALARM_IDS, 'has_leak');
    const noLeakQuery = buildHasChildQuery(NO_LEAK_ALARM_IDS, 'no_leak');
    const hasLeakClause = hasLeakQuery;
    const noLeakClause = {
      bool: {
        filter: {
          bool: {
            filter: noLeakQuery,
            must_not: hasLeakQuery
          }
        }
      }
    };
    const interruptedQuery = buildHasChildQuery(INTERRUPTED_ALARM_IDS, 'interrupted');
    const interruptedClause = {
      bool: {
        filter: interruptedQuery,
        must_not: [hasLeakQuery, noLeakQuery]
      }
    };
    const delayedQuery = buildHasChildQuery(DELAYED_ALARM_IDS, 'delayed');
    const delayedClause = {
      bool: {
        filter: delayedQuery,
        must_not: [hasLeakQuery, noLeakQuery, interruptedQuery]
      }
    };
    const skippedClause = {
      bool: {
        filter: buildHasChildQuery(SKIPPED_ALARM_IDS, 'skipped'),
        must_not: [hasLeakQuery, noLeakQuery, interruptedQuery, delayedQuery]
      }
    };
    const unknownClause = {
      bool: {
        must_not: buildHasChildQuery(ALL_ZIT_ALARM_IDS)
      }
    };
    const leakStatusClauses = {
      has_leak: hasLeakClause,
      no_leak: noLeakClause,
      interrupted: interruptedClause,
      delayed: delayedClause,
      skipped: skippedClause,
      unknown: unknownClause
    };

    return {
      bool: {
        should: _.chain(leakStatusClauses).pick(leakStatusFilters).values().value()
      }
    };
  }

  _buildOnboardingQuery(endDate) {
    return {
      nested: {
        path: 'onboarding',
        query: {
          bool: {
            filter: [
              {
                range: {
                  'onboarding.event': {
                    gte: 2
                  }
                }
              },
              {
                range: {
                  'onboarding.created_at': {
                    lte: endDate
                  }
                }
              }
            ]
          }
        }
      }
    };
  }

  _buildSubscriptionQuery(subscriptionFilters) {
    const noSubscriptionClause = _.find(subscriptionFilters, _.matches('no_subscription')) ? 
      [{
        bool: {
          must_not: {
            exists: {
              field: 'account.subscription'
            }
          }
        }
      }] :
      [];
    const subscriptionStatusClause = subscriptionFilters.some(status => status != 'no_subscription') ?
      [{
        bool: {
          filter: {
            terms: {
              'account.subscription.status': subscriptionFilters
            }
          }
        }
      }] :
      [];

    return {
      bool: {
        should: [
          ...subscriptionStatusClause,
          ...noSubscriptionClause
        ]
      }
    };
  }

  _categorizeLeakStatus(result) {
    const { _source, matched_queries = [] } = result;
    const hasLeak = _.find(matched_queries, _.matches('has_leak')) && 'has_leak';
    const noLeak = !hasLeak && _.find(matched_queries, _.matches('no_leak')) && 'no_leak';
    const interrupted = !hasLeak && !noLeak && _.find(matched_queries, _.matches('interrupted')) && 'interrupted';
    const delayed = !hasLeak && !noLeak && _.find(matched_queries, _.matches('delayed')) && 'delayed';
    const delayedInterrupted = interrupted && delayed && 'delayed_interrupted';
    const unknown = !hasLeak && !noLeak && !delayed && !interrupted && 'unknown';

    return {
      ..._source,
      leak_status: hasLeak || noLeak || delayedInterrupted || delayed || interrupted || unknown
    };
  }

  _buildTestDeviceQuery() {
    return {
      bool: {
        must_not: {
          term: {
            is_test_device: true
          }
        }
      }
    };
  }

  _queryMonthlyIndex(size, page, index, filterQueries) {
    const query = {
      index,
      type: 'icd',
      ...this.calculatePaging({ size, page }),
      _sourceInclude: [
        'id',
        'device_id',
        'account'
      ],
      body: {
        query: {
          bool: {
            filter: filterQueries.filter(query => !_.isEmpty(query))
          }
        }
      }
    };

    return this.elasticsearchClient.search(query)
      .then(result => ({
        total: result.hits.total,
        items: result.hits.hits.map(item => this._categorizeLeakStatus(item))
      }));
  }
}

export default new DIFactory(ActivityLogIndex, [elasticsearch.Client]);
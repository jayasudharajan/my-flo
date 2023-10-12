import elasticsearch from 'elasticsearch';
import ElasticsearchMonthlyLogIndex from '../utils/ElasticsearchMonthlyLogIndex';
import DIFactory from  '../../../util/DIFactory';

class AlertsIndex extends ElasticsearchMonthlyLogIndex {
  
  constructor(elasticsearchClient) {
    super('alerts', elasticsearchClient);
  }

  getICDsLeakTestStatus(icdIds, startDate, endDate) {
    return this.elasticsearchClient.search({
      index: this._getIndexNames(startDate, endDate),
      type: 'alert',
      size: 0,
      body: {
        query: this._createQuery({
          filter: {
            alarm_id: [32, 39, 40, 41, 42, 5, 34, 28, 29, 30, 31],
            icd_id: icdIds,
            incident_time: {
              gte: startDate,
              lte: endDate
            }
          }
        }),
        aggs: {
          icds: {
            terms: {
              field: 'icd_id',
              size: icdIds.length
            },
            aggs: {
              alarm_ids: {
                terms: {
                  field: 'alarm_id',
                  order: { 
                    most_recent: 'desc'
                  }
                },
                aggs: {
                  most_recent: {
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
    .then(results => {
      return results.aggregations.icds.buckets
        .map(({ key: icdId, alarm_ids: { buckets: alarmTypes } }) => ({
          id: icdId,
          status: categorizeLeakTestStatus(alarmTypes)
        }))
        .reduce((acc, icdStatus) => ({
          ...acc,
          [icdStatus.id]: icdStatus.status
        }), {});
    });
  }
}

function categorizeLeakTestStatus(alarmTypes) {
  const hasLeak = alarmTypes.some(({ key }) => key >= 28 && key <= 31);
  const noLeak = !hasLeak && alarmTypes.some(({ key }) => key == 5 || key == 34);
  const interrupted = !hasLeak && !noLeak && alarmTypes.some(({ key }) => key == 32 || (key >= 39 && key <= 41));
  const delayed = !hasLeak && !noLeak && alarmTypes.some(({ key }) => key == 42);

  if (hasLeak) {
    return 'has_leak';
  } else if (noLeak) {
    return 'no_leak';
  } else if (interrupted && delayed ) {
    return 'interrupted_delayed';
  } else if (interrupted) {
    return 'interrupted';
  } else if (delayed) {
    return 'delayed';
  } else {
    return 'unknown';
  }
}

export default new DIFactory(AlertsIndex, [elasticsearch.Client]);
import _ from 'lodash';
import moment from 'moment';
import postgres from 'pg';
import DIFactory from  '../../../util/DIFactory';
import squel from 'squel';

const SubscriptionFilters = [
  'canceled',
  'trialing',
  'active',
  'unpaid',
  'past_due'
];

class LeakDayService {
  constructor(postgresClientProvider) {
    this.postgresConnection = postgresClientProvider();
  }

  _query(query, values) {

    return this.postgresConnection
      .then(postgresClient => 
        postgresClient.query(query, values)
      );
  }

  _buildLeakStatusFilter(query, leakStatuses = []) {
    const leakStatusClauses = {
      has_leak: 'sum(has_leak) > 0',
      no_leak: '(sum(no_leak) > 0 AND sum(has_leak) = 0)',
      delayed_interrupted: '(sum(delayed_interrupted) > 0 AND sum(has_leak) = 0 AND sum(no_leak) = 0)',
      skipped: '(sum(skipped) > 0 AND sum(has_leak) = 0 AND sum(no_leak) = 0 AND sum(delayed_interrupted) = 0)',
      unknown: '(sum(has_leak) = 0 AND sum(no_leak) = 0 AND sum(delayed_interrupted) = 0 AND sum(skipped) = 0)'
    };
    const expr = leakStatuses
      .reduce((acc, leakStatus) => {
        const clause = leakStatusClauses[leakStatus];

        return clause ? acc.or(clause) : acc
      }, squel.useFlavour('postgres').expr());

    return query.having(expr);
  }

  _buildLeakStatusCountQuery(selection, dateRange, filters, pageSize, pageNumber, leakOrder) {
    const { 
     start_date,
     end_date
    } = dateRange;
    const { 
      is_subscribed, 
      leak_status = [] 
    } = filters;
    const offset = Math.max(pageNumber - 1, 0) * pageSize;
    const query = squel.useFlavour('postgres')
      .select()
      .from('devices')
      .left_join('leak_days', null, 'devices.icd_id = leak_days.icd_id')
      .where('installed_at <= ?::timestamp OR awoken_at <= ?::timestamp', end_date, end_date)
      .where('leak_day >= ?::timestamp AND leak_day <= ?::timestamp', start_date, end_date)
      .group('devices.icd_id')
      .group('device_id')
      .group('subscription_status')
      .limit(pageSize).offset(offset);

    selection
      .forEach(({ field, as }) => query.field(field, as));

    // Subscription filter
    if (!_.isNull(is_subscribed) && !_.isUndefined(is_subscribed)) {
      const subscriptionStatuses = ['active', 'trialing']
        .map(status => SubscriptionFilters.indexOf(status) + 1);
      const filterExpr = squel.useFlavour('postgres').expr();

      if (is_subscribed) {
        filterExpr
          .and('subscription_status IN (?, ?)', ...subscriptionStatuses);
      } else {
        filterExpr
          .or('subscription_status NOT IN (?, ?)', ...subscriptionStatuses)
          .or('subscription_status IS NULL');
      }

      query.where(filterExpr);
    }

    // Leak status filter
    if (!_.isEmpty(leak_status)) {
      this._buildLeakStatusFilter(query, leak_status);
    }

    if (leakOrder) {
      query.order('has_leak', leakOrder === 'asc');
    }

    const {
      text,
      values
    } = query.toParam();

    return { query: text, values };
  }

  _categorizeLeakStatus(deviceLeakStatusCount) {
    if (deviceLeakStatusCount.has_leak > 0) {
      return 'has_leak';
    } else if (deviceLeakStatusCount.no_leak > 0) {
      return 'no_leak';
    } else if (deviceLeakStatusCount.delayed_interrupted > 0) {
      return 'delayed_interrupted';
    } else if (deviceLeakStatusCount.skipped > 0) {
      return 'skipped';
    } else {
      return 'unknown';
    }
  }

  _categorizeSubscriptionStatus(deviceLeakStatusCount) {
    return !deviceLeakStatusCount.subscription_status ?
      null :
      SubscriptionFilters[parseInt(deviceLeakStatusCount.subscription_status) - 1];
  }

  _sanitizeCounts(record = {}, columns = []) {
    return _.chain(record)
      .pick(columns)
      .mapValues(count => parseInt(count) || 0)
      .value();
  }

  retrieveLeakDayCountsByDevice(dateRange, filters, pageSize = 20, pageNumber = 1, leakOrder = 'desc') {
    const selection = [
      { field: 'devices.icd_id' }, 
      { field: 'devices.device_id' },
      { field: 'devices.subscription_status' },
      { field: 'sum(leak_days.has_leak)', as: 'has_leak' }, 
      { field: 'sum(leak_days.no_leak)', as: 'no_leak' }, 
      { field: 'sum(leak_days.delayed_interrupted)', as: 'delayed_interrupted' },
      { field: 'sum(leak_days.skipped)', as: 'skipped' },
      { field: 'count(devices.icd_id) over()', as: 'total_devices' }
    ];
    const { query, values } = this
      ._buildLeakStatusCountQuery(selection, dateRange, filters, pageSize, pageNumber, leakOrder);

    return this._query(query, values)
      .then(result => ({
        total: parseInt(result.rows[0] && result.rows[0].total_devices) || 0,
        data: result.rows.map(row => ({
          ..._.omit(row, ['total_devices']),
          ...this._sanitizeCounts(row, ['has_leak', 'no_leak', 'delayed_interrupted', 'skipped']),
          subscription_status: this._categorizeSubscriptionStatus(row),
          leak_status: this._categorizeLeakStatus(row)
        }))
      }));
  }

  retrieveDeviceLeakDayCountTotals(dateRange, filters) {
    const selection = [{ field: 'count(devices.icd_id) over()', as: 'total' }];
    const leakStatuses = filters.leak_status || [
      'has_leak',
      'no_leak',
      'delayed_interrupted',
      'skipped',
      'unknown'
    ];
    const leakStatusTotalPromies = leakStatuses
      .map(leakStatus => {
        const leakStatusFilter = {
          ...filters,
          leak_status: [leakStatus]
        };
        const { query, values } = this._buildLeakStatusCountQuery(selection, dateRange, leakStatusFilter, 1, 0);

        return this._query(query, values)
          .then(result => ({
            [leakStatus]: this._sanitizeCounts(result.rows[0], ['total']).total || 0
          }));
      });

    return Promise.all(leakStatusTotalPromies)
      .then((leakStatusTotals = []) => 
        leakStatusTotals
          .reduce(
            (acc, leakStatusTotal) => ({ ...acc, ...leakStatusTotal }), 
            {}
          )
      );
  }
}

export default new DIFactory(LeakDayService, ['PostgresClientProvider']);

import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TLeakStatus = t.enums.of([
  'has_leak',
  'no_leak',
  'delayed_interrupted',
  'skipped',
  'unknown'
]);

const TDateRange = t.refinement(
  t.struct({
    start_date: tcustom.ISO8601Date,
    end_date: tcustom.ISO8601Date
  }),
  s => s.start_date < s.end_date
);

TDateRange.getValidationErrorMessage = (actual, expected, path, context) => 'start_date and end_date should be ISO 8601 date, where start_date < end_date';

const TLeakDayFilters = t.struct({
    date_range: TDateRange,
    leak_status: t.maybe(t.list(TLeakStatus)),
    is_subscribed: t.maybe(t.Boolean)
  });

export default {
  retrieveLeakDayCountsByDevice: {
    query: t.struct({
      page: t.maybe(tcustom.Page),
      size: t.maybe(tcustom.Size),
      leak_order: t.maybe(tcustom.Order)
    }),
    body: TLeakDayFilters
  },
  retrieveDeviceLeakDayCountTotals: {
    body: TLeakDayFilters
  }
};

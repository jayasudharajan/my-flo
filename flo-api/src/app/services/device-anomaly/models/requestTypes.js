import t from 'tcomb-validation';
import TDeviceAnomaly from './TDeviceAnomalyAlert';

const TNumericString = t.refinement(t.String, s => t.Number.is(new Number(s).valueOf()));


export default {
  handleDeviceAnomalyEvent: {
    params: t.struct({
      type: TNumericString
    }),
    body: TDeviceAnomaly,
  },
  retrieveByAnomalyTypeAndDateRange: {
    params: t.struct({
      type: TNumericString
    }),
    query: t.struct({
      start_date: t.maybe(t.String),
      end_date: t.maybe(t.String)
    })
  }
};
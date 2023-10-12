import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TFixturesData from './TFixturesData';
import TFixturesForFeedbackData from './TFixturesForFeedbackData';
import TEventFeedback from './TEventFeedback';
import TEvent from './TEvent';
import TFixtureAverage from './TFixtureAverage';

const TIntegerString = t.refinement(t.String, s => Number.isInteger(new Number(s).valueOf()));
const TPositiveIntegerString = t.refinement(TIntegerString, s => s >= 0);
const TBooleanString = t.refinement(t.String, s => s == 'true' || s == 'false');

export default {
  logFloDetect: {
    params: t.struct({
      device_id: tcustom.DeviceId
    }),
    body: TFixturesData
  },
  retrieveFloDetectResults: {
    params: t.struct({
      request_id: tcustom.UUID
    })
  },
  retrieveByDeviceIdAndDateRange: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      start_date: t.maybe(tcustom.ISO8601Date),
      end_date: t.maybe(tcustom.ISO8601Date)
    }),
    query: t.struct({
      tz: t.maybe(t.String)
    })
  },
  retrieveByDeviceIdAndDateRangeWithStatus: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      start_date: t.maybe(tcustom.ISO8601Date),
      end_date: t.maybe(tcustom.ISO8601Date)
    }),
    query: t.struct({
      tz: t.maybe(t.String)
    })
  },  
  retrieveLatestByDeviceId: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      duration: TIntegerString
    }),
    query: t.struct({
      tz: t.maybe(t.String)
    })
  },
  retrieveLatestByDeviceIdWithStatus: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      duration: TIntegerString
    }),
    query: t.struct({
      tz: t.maybe(t.String)
    })
  },
  runFixturesDetection: {
    params: t.struct({
      device_id: tcustom.DeviceId
    }),
    body: t.struct({
      start_date: t.maybe(tcustom.ISO8601Date),
      end_date: t.maybe(tcustom.ISO8601Date)
    })
  },
  updateFixturesWithFeedback: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      start_date: tcustom.ISO8601Date,
      end_date: tcustom.ISO8601Date
    }),
    body: TFixturesForFeedbackData
  },
  retrieveLatestByDeviceIdInDateRange: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      duration: TIntegerString,
      start_date: tcustom.ISO8601Date,
      end_date: tcustom.ISO8601Date    
    }),
    query: t.struct({
      tz: t.maybe(t.String)
    })
  },
  retrieveLatestByDeviceIdInDateRangeWithStatus: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      duration: TIntegerString,
      start_date: tcustom.ISO8601Date,
      end_date: tcustom.ISO8601Date    
    }),
    query: t.struct({
      tz: t.maybe(t.String)
    })
  },
  updateEventChronologyWithFeedback: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      request_id: tcustom.UUID,
      start_date: tcustom.ISO8601Date
    }),
    body: TEventFeedback
  },
  retrieveEventChronologyPage: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      request_id: tcustom.UUID
    }),
    query: t.struct({
      size: t.maybe(TPositiveIntegerString),
      start: t.maybe(tcustom.ISO8601Date),
      desc: t.maybe(TBooleanString)
    })
  },
  batchCreateEventChronology: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      request_id: tcustom.UUID  
    }),
    body: t.struct({
      event_chronology: t.list(TEvent)
    })
  },
  logFixtureAverages: {
    body: TFixtureAverage
  },
  retrieveLatestFixtureAverages: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      duration: TIntegerString
    })
  }
}
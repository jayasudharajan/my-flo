import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TFixturesData from './TFixturesData';
import TFixturesForFeedbackData from './TFixturesForFeedbackData';

export default {
  logFixtureDetection: {
    params: t.struct({
      device_id: tcustom.DeviceId
    }),
    body: TFixturesData
  },
  retrieveFixtureDetectionResults: {
    params: t.struct({
      request_id: tcustom.UUID
    })
  },
  retrieveByDeviceIdAndDateRange: {
    params: t.struct({
      device_id: tcustom.DeviceId,
      start_date: t.maybe(tcustom.ISO8601Date),
      end_date: t.maybe(tcustom.ISO8601Date)
    })
  },
  retrieveLatestByDeviceId: {
    params: t.struct({
      device_id: tcustom.DeviceId
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
      request_id: tcustom.UUID,
      created_at: tcustom.ISO8601Date,
      device_id: tcustom.DeviceId
    }),
    body: TFixturesForFeedbackData
  },
}
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TEvent from './TEvent';
import TEventFeedback from './TEventFeedback';

const TEventChronology = t.struct.extend([
  TEvent,
  t.struct({
    request_id: tcustom.UUID,
    device_id: tcustom.DeviceId,
    feedback: t.maybe(TEventFeedback)
  })
]);

export default TEventChronology;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TProcessIntentRequest = t.struct({
  requestId: t.String,
  inputs: t.list(t.struct({
    intent: t.String,
    payload: t.maybe(t.Any)
  }))
});

export default {
  processIntentRequest: {
    body: TProcessIntentRequest
  }
};
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes'; 

const TEventFeedback = t.struct({
  case: t.Integer,
  correct_fixture: t.String
});

export default TEventFeedback;
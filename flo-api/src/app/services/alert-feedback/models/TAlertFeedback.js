import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TAlertCause from './TAlertCause';
import TFixture from './TFixture';
import TPlumbingFailure from './TPlumbingFailure';

const TAlertFeedback = t.struct({
  incident_id: t.String,
  icd_id: tcustom.UUIDv4,
  alarm_id: t.Integer,
  system_mode: t.Integer,
  cause: TAlertCause,
  should_accept_as_normal: t.Boolean,
  plumbing_failure: t.maybe(TPlumbingFailure),
  fixture: t.maybe(t.list(TFixture)),
  cause_other: t.maybe(t.String),
  plumbing_failure_other: t.maybe(t.String),
  action_taken: t.maybe(t.String)
});

export default TAlertFeedback;
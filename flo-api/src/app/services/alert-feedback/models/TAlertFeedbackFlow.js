import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TFlowType = t.enums.of([
  'list',
  'text'
]);

const TActionType = t.enums.of([
  'sleep_2h',
  'sleep_24h'
]);

const TAlertFeedbackStep = t.declare('TAlertFeedbackStep');

const TTaggedAlertFeedbackStep = t.struct({
  tag: t.String
});

const TAlertFeedbackStepOption = t.struct({
  display_text: t.maybe(t.String),
  sort_order: t.maybe(t.Integer),
  action: t.maybe(TActionType),
  property: t.String,
  value: t.maybe(t.union([t.Boolean, t.String, t.Integer])),
  flow: t.maybe(t.union([TAlertFeedbackStep, TTaggedAlertFeedbackStep]))
});


TAlertFeedbackStep.define(
  t.struct({
    title_text: t.String,
    type: TFlowType,
    options: t.list(TAlertFeedbackStepOption)
  })
);

const TAlertFeedbackFlow = t.struct({
  alarm_id: t.Integer,
  system_mode: t.Integer,
  flow: TAlertFeedbackStep,
  flow_tags: t.maybe(t.dict(t.String, TAlertFeedbackStep))
});

export default TAlertFeedbackFlow;
import t from 'tcomb-validation';

const TTriggerIdentityLog = t.struct({
  trigger_identity: t.String,
  user_id: t.String,
  flo_trigger_id: t.String,
  trigger_slug: t.String,
  ifttt_source: t.Any
});

TTriggerIdentityLog.create = data => TTriggerIdentityLog(data);

export default TTriggerIdentityLog;
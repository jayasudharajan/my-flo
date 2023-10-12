import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TProfileParams from './TProfileParams';

const TAlarmOperation = t.interface({
  action_id: t.Number,
  delay: t.Number
});

const TAlarmOperations = t.interface({
  alarm_id: t.Number,
  system_mode: t.Number,
  operations: t.list(TAlarmOperation)
});

const THealthTestConfig = t.interface({
  enabled: t.Boolean,
  start_time: t.String,
  end_time: t.String,
  allowed_percent_of_pressure_to_drop: t.Number,
  allowed_slope_diff: t.Number,
  max_round_duration: t.Number
});

const TFlosenseProfileFeature = t.interface({
  name: t.maybe(t.String),
  threshold: t.maybe(t.Number),
  violation: t.maybe(t.Number),
  minimum_diff: t.maybe(t.Number),
  model: t.maybe(t.String),
  model_link: t.maybe(t.String),
  model_checksum: t.maybe(t.String)
});

const TFlosenseProfile = t.interface({
  name: t.String,
  static: t.maybe(t.Boolean),
  features: t.maybe(t.list(TFlosenseProfileFeature))
});

const TDirectiveExecutionError = t.interface({
  code: t.Number,
  message: t.String
});

const TGetVersion = t.interface({
  os: t.String,
  ultima: t.maybe(t.String),
  zigbee: t.maybe(t.String)
});

const TGetProfileResponse = t.interface({
  flow_rate: TProfileParams,
  per_event_flow: TProfileParams,
  per_event_duration: TProfileParams,
  min_pressure: TProfileParams,
  max_pressure: TProfileParams,
  min_temperature: TProfileParams,
  max_temperature: TProfileParams
});

const TGetAlarmOperations = t.interface({
  alarm_operations: t.list(TAlarmOperations)
});

const TGetHealthTestConfig = t.interface({
  enabled: t.Boolean,
  start_time: t.String,
  end_time: t.String,
  allowed_percent_of_pressure_to_drop: t.Number,
  allowed_slope_diff: t.Number,
  max_round_duration: t.Number
});

const TUpdateDebugModeConfig = t.interface({
  success: t.Boolean
});

const TGetDebugModeConfig = t.interface({
  enabled: t.Boolean
});

const TUpdateVpnConfiguration = t.interface({
  success: t.Boolean
});

const TGetVpnConfiguration = t.interface({
  enabled: t.Boolean
});

const TSetOrUpdateOrRemoveFlosenseConfig = t.interface({
  progress: t.maybe(t.String),
  result: t.maybe(t.Boolean),
  error: t.maybe(TDirectiveExecutionError)
});

const TGetFlosenseConfig = t.interface({
  auto_swap: t.Boolean,
  active_profile: t.String,
  profiles: t.list(TFlosenseProfile)
});

const TGetAwayModeConfig = t.interface({
  enabled: t.Boolean,
  schedule: t.maybe(t.String)
});

const TSetAwayModeConfig = t.interface({
  result: t.maybe(t.Boolean)
});

const TGetHealthTestConfigV2 = t.interface({
  configs: t.list(THealthTestConfig)
});

const TGetActiveFlosenseProfile = t.interface({
  name: t.String,
  static: t.Boolean,
  features: t.list(TFlosenseProfileFeature)
});

const TDirectiveResponse = t.struct({
  id: t.String,
  directive_id: t.maybe(t.String),
  directive: t.String,
  device_id: tcustom.DeviceId,
  time: tcustom.ISO8601Date,
  ack_topic: t.String,
  data: t.maybe(t.union([
    TGetProfileResponse,
    TGetVersion,
    TGetAlarmOperations,
    TGetHealthTestConfig,
    TUpdateDebugModeConfig,
    TGetDebugModeConfig,
    TUpdateVpnConfiguration,
    TGetVpnConfiguration,
    TGetFlosenseConfig,
    TGetAwayModeConfig,
    TSetAwayModeConfig,
    TGetHealthTestConfigV2,
    TSetOrUpdateOrRemoveFlosenseConfig,
    TGetActiveFlosenseProfile
  ]))
});

export default TDirectiveResponse;
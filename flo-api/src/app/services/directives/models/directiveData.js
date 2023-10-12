import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { createPartialValidator } from '../../../../util/validationUtils';

const TEmptyData = t.struct({});

const TOpenValveData = TEmptyData;

const TCloseValveData = TEmptyData;

const TSetSystemModeData = t.struct({
  mode: t.Integer
});

const TUpgradeTarget = t.enums.of([
  'agent-1',
  'agent-2'
]);

const TUpgradeAlg = t.enums.of([
  'sha1'
]);

const TUpgradeDirectiveData = t.struct({
  target: TUpgradeTarget,
  url: tcustom.URL,
  alg: TUpgradeAlg,
}, {
  defaultProps: {
    target: 'agent-1',
    alg: 'sha1'
  }
});

const TUpgradeUltimaData = TUpgradeDirectiveData;

const TUpgradeKernelData = TUpgradeDirectiveData.extend({
  factory_reset: t.Boolean
}, 'UpgradeKernelData');

const TUpgradeAgent1Data = t.refinement(
  TUpgradeDirectiveData.extend(
    {},
    {
      target: 'agent-2'
    }
  ),
  data => data.target !== 'agent-1',
  'UpgradeAgent1Data'
);

const TUpgradeAgent2Data = t.refinement(
  TUpgradeUltimaData,
  data => data.target !== 'agent-2',
  'UpgradeAgent1Data'
);

const TUpgradeCertificatesData = TUpgradeDirectiveData;

const TUpgradeZigBeeModule = TUpgradeDirectiveData;

const TPowerResetData = TEmptyData;

const TFactoryResetData = t.struct({
  reset_kernel: t.Boolean,
  reset_ultima: t.Boolean
});

const TVRZITData = t.struct({
  round_id: tcustom.UUIDv4,
  pressure_percentage: t.Number,
  reference_time: t.Integer,
  reference_point_count: t.Integer,
  slope_decrease: t.Number,
  stage_1_time_factor: t.Number,
  stage_2_time_factor: t.Number,
  stage_3_time_factor: t.Number,
  stage_4_time_factor: t.Number
}, {
  defaultProps: {
    pressure_percentage: 3.0,
    reference_time: 120,
    reference_point_count: 3,
    slope_decrease: 0.6,
    stage_1_time_factor: 0.5,
    stage_2_time_factor: 1,
    stage_3_time_factor: 2,
    stage_4_time_factor: 4
  }
});

const THomeAway = t.struct({
  home: t.Number,
  away: t.Number
});

const TUpdateProfileData = t.struct({
  flow_rate: t.maybe(THomeAway),
  per_event_flow: t.maybe(THomeAway),
  per_event_duration: t.maybe(THomeAway),
  min_pressure: t.maybe(THomeAway),
  max_pressure: t.maybe(THomeAway),
  min_temperature: t.maybe(THomeAway),
  max_temperature: t.maybe(THomeAway)
});

const TGetProfileData = t.maybe(TEmptyData);

const TGetVersionData = TEmptyData;

const TAlarmOperation = t.struct({
  action_id: t.Number,
  delay: t.Number
});

const TAlarmOperations = t.struct({
  alarm_id: t.Number,
  system_mode: t.Number,
  operations: t.list(TAlarmOperation)
});

const TUpdateValvePreferences = t.struct({
  alarm_operations: t.list(TAlarmOperations),
});

const TGetValvePreferences = t.maybe(TEmptyData);

const TUpdateHealthTestConfig = t.struct({
  enabled: t.maybe(t.Boolean),
  start_time: t.maybe(t.String),
  end_time: t.maybe(t.String),
  allowed_percent_of_pressure_to_drop: t.maybe(t.Number),
  allowed_slope_diff: t.maybe(t.Number),
  max_round_duration: t.maybe(t.Number)
});

const TUpdateHealthTestConfigV2 = t.struct({
  configs: t.list(TUpdateHealthTestConfig)
});

const TGetHealthTestConfig = t.maybe(TEmptyData);

const TGetVpnConfiguration = t.maybe(TEmptyData);

const TUpdateVpnConfiguration = t.struct({
  enabled: t.Boolean
});

const TGetDebugModeConfiguration = t.maybe(TEmptyData);

const TUpdateDebugModeConfiguration = t.struct({
  enabled: t.Boolean
});

const TGetFlosenseConfiguration = t.maybe(TEmptyData);

const TFlosenseProfileFeature = t.struct({
  name: t.String,
  threshold: t.Number,
  violation: t.Number,
  minimum_diff: t.Number,
  model: t.String,
  model_link: t.String,
  model_checksum: t.String
});

const TFlosenseProfile = t.struct({
  name: t.String,
  swap_condition: t.struct({}),
  features: t.maybe(
    t.list(TFlosenseProfileFeature)
  )
});

const TSetFlosenseConfiguration = t.struct({
  auto_swap: t.Boolean,
  active_profile: t.String,
  profiles: t.list(TFlosenseProfile)
});

const TUpdateFlosenseConfiguration = t.struct({
  auto_swap: t.maybe(t.Boolean),
  active_profile: t.maybe(t.String),
  profiles: t.maybe(
    t.list(createPartialValidator(TFlosenseProfile))
  )
});

const TRemoveFlosenseProfile = t.struct({
  profiles: t.list(
    t.struct({
      name: t.String
    })
  )
});

const TGetActiveFlosenseProfile = t.maybe(TEmptyData);

const TSelectFlosenseProfile = t.struct({
  name: t.String
});

const TGetAwayWaterSchedule = t.maybe(TEmptyData);

const TSetAwayWaterSchedule = t.struct({
  enabled: t.Boolean,
  schedule: t.maybe(t.String)
});

const TSetPESSchedule = t.struct({
  sm: t.enums.of(['home', 'away']),
  schedules: t.list(t.interface({
    name: t.String,
    max_duration: t.Number,
    max_volume: t.Number,
    max_rate: t.Number,
    max_rate_duration: t.Number,
    schedule: t.String
  }))
});

const TGetPESSchedule = t.struct({
  sm: t.enums.of(['home', 'away'])
});

export const directiveDataMap = {
  'open-valve': TOpenValveData,
  'close-valve': TCloseValveData,
  'set-system-mode': TSetSystemModeData,
  'upgrade-ultima': TUpgradeUltimaData,
  'upgrade-kernel': TUpgradeKernelData,
  'upgrade-agent-1': TUpgradeAgent1Data,
  'upgrade-agent-2': TUpgradeAgent2Data,
  'upgrade-certificates': TUpgradeCertificatesData,
  'upgrade-zigbee-module': TUpgradeZigBeeModule,
  'power-reset': TPowerResetData,
  'factory-reset': TFactoryResetData,
  'update-profile': TUpdateProfileData,
  'get-profile': TGetProfileData,
  'get-version': TGetVersionData,
  'vrzit': TVRZITData,
  'get-alarm-operations': TGetValvePreferences,
  'update-alarm-operations': TUpdateValvePreferences,
  'get-health-test-config': TGetHealthTestConfig,
  'update-health-test-config': TUpdateHealthTestConfig,
  'get-health-test-config-v2': TGetHealthTestConfig,
  'update-health-test-config-v2': TUpdateHealthTestConfigV2,
  'get-vpn-configuration': TGetVpnConfiguration,
  'update-vpn-configuration': TUpdateVpnConfiguration,
  'get-debug-mode-config': TGetDebugModeConfiguration,
  'update-debug-mode-config': TUpdateDebugModeConfiguration,
  'get-flosense-config': TGetFlosenseConfiguration,
  'set-flosense-config': TSetFlosenseConfiguration,
  'update-flosense-config': TUpdateFlosenseConfiguration,
  'remove-flosense-profile': TRemoveFlosenseProfile,
  'get-active-flosense-profile': TGetActiveFlosenseProfile,
  'select-flosense-profile': TSelectFlosenseProfile,
  'get-away-mode-config': TGetAwayWaterSchedule,
  'set-away-mode-config': TSetAwayWaterSchedule,
  'set-pes-schedule': TSetPESSchedule,
  'get-pes-schedule': TGetPESSchedule
};

export const TDirective = t.enums.of(_.keys(directiveDataMap));
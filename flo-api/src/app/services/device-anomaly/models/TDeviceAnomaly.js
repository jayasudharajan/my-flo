import t from 'tcomb-validation';
import {wrapEnum} from '../../../../util/validationUtils';

const TDeviceAnomaly = wrapEnum(t.enums({
  1: 'NO_FLOW_24H',
  2: 'NO_FLOW_48H',
  3: 'NO_FLOW_72H',
  4: 'NO_DATA_24H',
  5: 'NO_DATA_48H',
  6: 'NO_DATA_72H',
  7: 'WATER_SHUTOFF',
  8: 'SLEEP_MODE',
  9: 'AWAY_MODE',
  10: 'LOW_TEMPERATURE_BELOW_30F_10M',
  11: 'HIGH_TEMPERATURE_ABOVE_100F_10M',
  12: 'HIGH_PRESSURE_ABOVE_150PSI_5M',
  13: 'NO_HEALTH_TEST_IN_24H',
  14: 'VALVE_STUCK_IN_TRANSITION_1H',
  15: 'BROKEN_PT_SENSOR'
}));

export default TDeviceAnomaly;
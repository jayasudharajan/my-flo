import t from 'tcomb-validation';
import TLeakState from './TLeakState';
import TSystemMode from './TSystemMode';
import TValveState from './TValveState';
import TOnlineState from './TOnlineState';
import { SystemModeState, ValveState, LeakState, OnlineState } from './DevicesStates';

const ExactString = str => t.refinement(t.String, s => s === str);

const TState = t.union([
  t.interface({ sn: ExactString(SystemModeState), st: TSystemMode }),
  t.interface({ sn: ExactString(ValveState), st: TValveState }),
  t.interface({ sn: ExactString(LeakState), st: TLeakState }),
  t.interface({ sn: ExactString(OnlineState), st: TOnlineState })
]);

export default TState;
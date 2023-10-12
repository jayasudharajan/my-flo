import { StrictSchema } from 'morphism';
import _ from 'lodash';

// ===============================================
// Common
// ===============================================

export enum SystemModeName {
  HOME = 'home',
  AWAY = 'away',
  SLEEP = 'sleep'
}

export enum SystemMode {
  HOME = 2,
  AWAY = 3,
  SLEEP = 5
}

export enum ValveStateName {
  OPEN = 'open',
  CLOSED = 'closed',
  IN_TRANSITION = 'inTransition',
  BROKEN = 'broken',
  UNKNOWN = 'unknown',
}

export enum ValveState {
  UNKNOWN = -1,
  CLOSED = 0,
  OPEN = 1,
  IN_TRANSITION = 2,
  BROKEN = 3
}

// ===============================================
// Dynamo
// ===============================================


type Integer = number;

export interface DynamoDevice {
  id: string;
  device_id: string;
  is_paired?: boolean;
  location_id: string;
  nickname?: string;
  should_inherit_system_mode?: boolean;
  device_model?: string;
  device_type?: string;
  target_system_mode?: SystemModeName;
  puck_configured_at?: string;
  target_valve_state?: ValveStateName;
  irrigation_type?: string;
  revert_minutes?: Integer;
  revert_mode?: SystemModeName;
  revert_scheduled_at?: string;
}

// ===============================================
// Postgres
// ===============================================

export interface PostgresDevice {
  id: string;
  mac_address: string;
  is_paired?: boolean | null;
  location_id: string;
  nickname?: string | null;
  should_inherit_system_mode?: boolean | null;
  device_model?: string | null;
  device_type?: string | null;
  system_mode_target?: SystemMode | null;
  system_mode_revert_minutes?: Integer | null;
  system_mode_revert_mode?: SystemMode | null;
  system_mode_revert_scheduled_at?: string | Date | null;
  puck_configured_at?: string | null;
  valve_state_target?: ValveState | null;
  irrigation_type?: string | null;
}

// ===============================================
// Conversion
// ===============================================

export const DynamoToPgDeviceSchema: StrictSchema<PostgresDevice, DynamoDevice> = {
  id: 'id',
  mac_address: 'device_id',
  is_paired: 'is_paired',
  location_id: 'location_id',
  nickname: 'nickname',
  should_inherit_system_mode: 'should_inherit_system_mode',
  device_model: 'device_model',
  device_type: 'device_type',
  puck_configured_at: 'puck_configured_at',
  valve_state_target: (input: DynamoDevice) => {
    switch (input.target_valve_state) {
      case ValveStateName.BROKEN:
        return ValveState.BROKEN;
      case ValveStateName.CLOSED:
        return ValveState.CLOSED;
      case ValveStateName.IN_TRANSITION:
        return ValveState.IN_TRANSITION;
      case ValveStateName.OPEN:
        return ValveState.OPEN;
      case ValveStateName.UNKNOWN:
        return ValveState.UNKNOWN;
      default:
        return undefined;
    }
  },
  irrigation_type: 'irrigation_type',
  system_mode_target: (input: DynamoDevice) => {
    switch (input.target_system_mode) {
      case SystemModeName.HOME:
        return SystemMode.HOME;
      case SystemModeName.AWAY:
        return SystemMode.AWAY;
      case SystemModeName.SLEEP:
        return SystemMode.SLEEP
      default:
        return undefined;
    }
  },
  system_mode_revert_minutes: 'revert_minutes',
  system_mode_revert_mode: (input: DynamoDevice) => {
    switch (input.revert_mode) {
      case SystemModeName.HOME:
        return SystemMode.HOME;
      case SystemModeName.AWAY:
        return SystemMode.AWAY;
      case SystemModeName.SLEEP:
        return SystemMode.SLEEP
      default:
        return undefined;
    }
  },
  system_mode_revert_scheduled_at: 'revert_scheduled_at'
}

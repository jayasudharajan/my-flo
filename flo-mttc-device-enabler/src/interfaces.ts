interface ReferenceTime {
  data_start_date: string
}

export interface MicroLeakTestTimeRecord {
  reference_time?: ReferenceTime
}

export interface Device {
  device_id: string
  id: string
}

export enum OnboardingEvent {
  PAIRED = 1,
  INSTALLED = 2,
  SYSTEM_MODE_UNLOCKED = 3
}
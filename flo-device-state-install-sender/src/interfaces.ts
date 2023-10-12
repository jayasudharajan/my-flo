export interface OnboardingLog {
  icd_id: string,
  created_at: string,
  event: number
}

export enum OnboardingEvent {
  PAIRED = 1,
  INSTALLED = 2,
  SYSTEM_MODE_UNLOCKED = 3
}

export interface Device {
  id: string,
  device_id: string
}

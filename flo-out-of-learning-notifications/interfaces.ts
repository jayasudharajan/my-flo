export interface Icd {
  id: string,
  location_id: string
}

export interface User {
  id: string,
  email: string
}

export interface Location {
  location_id: string,
  account_id: string
}

export interface Account {
  id: string,
  owner_user_id: string
}

export interface UserDetails {
  firstname: string,
  lastname: string
}

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

export interface UserInfo {
  email: string,
  firstName: string,
  lastName: string,
  userId: string,
  pushNotificationTokens: PushNotificationToken[]
}

export interface PushNotificationToken {
  aws_endpoint_id: string,
  is_disabled: number,
  mobile_device_id: string,
  user_id: string
}

export interface EventData {
  email: string,
  firstName: string,
  lastName: string,
  userId: string,
  awsEndpointId: string,
  eventCreatedAt: string
}
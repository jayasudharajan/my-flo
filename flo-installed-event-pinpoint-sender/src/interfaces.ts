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

export interface Icd {
  id: string,
  location_id: string,
  nickname: string
}

export interface Account {
  id: string,
  owner_user_id: string
}

export interface Location {
  location_id: string,
  account_id: string
}

export interface User {
  id: string,
  email: string
}

export interface UserDetails {
  firstname: string,
  lastname: string
}

export interface UserInfo {
  email: string,
  firstName: string,
  lastName: string,
  userId: string,
  pushNotificationTokens: PushNotificationToken[],
  device: Icd
}

export interface PushNotificationToken {
  aws_endpoint_id: string,
  is_disabled: number,
  mobile_device_id: string,
  user_id: string,
  token: string,
  client_type: number
}

export interface EventData {
  email: string,
  firstName: string,
  lastName: string,
  userId: string,
  device: Icd,
  clientType: number,
  token: string,
  awsEndpointId: string,
  createdAt: string
}

export interface OnboardingLog {
  icd_id: string;
  created_at: string;
  event: number;
}

export interface User {
  email: string;
}

export interface UserDetails {
  user_id: string;
  firstname: string;
  lastname: string;
  locale: string;
}

export interface UserInfo {
  email: string;
  firstName: string;
  lastName: string;
}

export interface Icd {
  id: string;
  location_id: string;
}

export interface Location {
  location_id: string;
  account_id: string;
}

export interface UserLocationRole {
  user_id: string;
  location_id: string;
}

export interface RecordImage<T> {
  old: T;
  new: T;
}
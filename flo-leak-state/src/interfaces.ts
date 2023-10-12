export enum EntityActivityAction {
  CREATED = 'created',
  UPDATED = 'updated',
  DELETED = 'deleted'
}

export enum EntityActivityType {
  DEVICE = 'device',
  LOCATION = 'location',
  ACCOUNT = 'account',
  USER = 'user',
  ALERT = 'alert'
}

interface SimpleAlarm {
  id: number;
  severity: string;
}

export enum IncidentStatus {
  RECEIVED = 'received',
  FILTERED = 'filtered',
  TRIGGERED = 'triggered',
  RESOLVED = 'resolved'
}

interface Device {
  id: string;
  macAddress: string;
}

export interface EntityActivityItem {
  id: string;
  alarm: SimpleAlarm;
  device: Device;
  status: string;
  reason?: string;
  locationId: string;
  systemMode: string;
  createAt: string;
  updateAt: string;
}

export interface EntityActivityMessage {
  id: string;
  date: string;
  type: EntityActivityType;
  action: EntityActivityAction;
  item: EntityActivityItem;
}

export interface TopicOffset {
  partition: number;
  offset: string;
}
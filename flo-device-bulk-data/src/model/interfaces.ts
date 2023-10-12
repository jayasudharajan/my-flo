import moment from 'moment';

export type DateTime = moment.Moment;

export enum FileType {
  Telemetry,
  Logs
}

export interface SignedBlobHeader {
  signature: string,
  macAddress: string,
  signatureType: string,
  startDate: DateTime,
  dataVersion: string
}

export type Base64 = string

export interface SignedBlob {
  header: SignedBlobHeader,
  content: Base64
}

export interface StockICD {
  device_id: string,
  icd_client_key: string,
  icd_client_cert: string
}

export interface HeadFileParameters {
  type: string,
  macAddress: string,
  signature: string,
  createdAt: string,
  dataVersion: string
}
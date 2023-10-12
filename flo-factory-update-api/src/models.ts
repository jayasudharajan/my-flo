import * as t from 'io-ts';

const QrCodeV1Codec = t.type({
  i: t.string,
  e: t.string
});

const QrCodeV2Codec = t.string;

const QrCodeCodec = t.union([
  QrCodeV1Codec,
  QrCodeV2Codec
]);

export const QrCodeDataCodec = t.type({
  data: QrCodeCodec
});

export type QrCodeData = t.TypeOf<typeof QrCodeDataCodec>;

export const StockIcdCodec = t.type({
  device_id: t.string,
  ap_name: t.string
});

export type StockIcd = t.TypeOf<typeof StockIcdCodec>;

export const RegistrationDataCodec = t.partial({
  ssh_private_key: t.string
});

export type RegistrationData = t.TypeOf<typeof RegistrationDataCodec>;
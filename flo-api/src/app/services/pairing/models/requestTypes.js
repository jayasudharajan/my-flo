import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TQRCode from './TQRCode';

export default {
  scanQRCode: {
    body: t.union([
      t.interface({
        data: t.union([TQRCode, t.String])
      }),
      TQRCode
    ])
  },
  retrievePairingDataByICDId: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    })
  },
  unpairDevice: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    })
  },
  initPairing: {
    body: t.struct({
      data: t.union([TQRCode, t.String])
    })
  },
  completePairing: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    }),
    body: t.struct({
      timezone: t.String,
      device_id: tcustom.DeviceId
    })
  }
};
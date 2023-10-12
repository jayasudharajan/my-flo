import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  generate: {
    body: t.struct({
      location_id: tcustom.UUIDv4
    })
  },
  getDownloadInfo: {
    params: t.struct({
      location_id: tcustom.UUIDv4
    })
  },
  redeem: {
    body: t.struct({
      location_id: tcustom.UUIDv4
    })
  },
  regenerate: {
    body: t.struct({
      location_id: tcustom.UUIDv4
    })
  }
};
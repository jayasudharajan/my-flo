import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TVPNWhitelist = t.struct({
  device_id: tcustom.DeviceId,
  start: t.Number,
  end: t.Number
});

TVPNWhitelist.create = data => TVPNWhitelist(data);

export default TVPNWhitelist;
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TOnboardingEvent from './TOnboardingEvent';

export default {
  doOnDeviceInstalled: {
		body: t.struct({
			device_id: tcustom.DeviceId
		})
	},
  doOnDevicePaired: {
    body: t.struct({
      id: tcustom.UUIDv4,
      location_id: tcustom.UUIDv4
    })
  },
  doOnSystemModeUnlocked: {
    body: t.struct({
      icd_id: tcustom.UUIDv4
    })
  },
  doOnDeviceEvent: {
    body: t.struct({
      id: tcustom.UUID,
      device_id: tcustom.DeviceId,
      event: t.struct({
        name: t.enums.of(TOnboardingEvent.getNames())
      })
    })
  },
  retrieveCurrentState: {
    params: t.struct({
      icd_id: tcustom.UUIDv4
    })
  }
}
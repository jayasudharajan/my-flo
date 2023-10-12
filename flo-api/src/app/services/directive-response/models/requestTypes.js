import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TDirectiveResponse from './TDirectiveResponse';

export default {
	logDirectiveResponse: {
		params: t.struct({
			device_id: tcustom.DeviceId
		}),
		body: TDirectiveResponse
	}
}
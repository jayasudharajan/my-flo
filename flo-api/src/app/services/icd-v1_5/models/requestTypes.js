import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { createCrudReqValidation } from '../../../../util/validationUtils';
import TICD from './TICD';

export default {
	...createCrudReqValidation({ hashKey: 'id' }, TICD),
	retrieveByLocationId: {
		params: t.struct({
			location_id: tcustom.UUIDv4
		})
	},
	retrieveByDeviceId: {
			params: t.struct({
				device_id: tcustom.DeviceId
			})
	}
};
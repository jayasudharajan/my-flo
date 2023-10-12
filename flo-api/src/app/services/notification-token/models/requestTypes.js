import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TNotificationToken from './TNotificationToken';
import TDeviceType from './TDeviceType';
import { createCrudReqValidation } from '../../../../util/validationUtils';

const paramsValidator = t.struct({ user_id: tcustom.UUIDv4 });

export default {
	...createCrudReqValidation({ hashKey: 'user_id' }, TNotificationToken),
	addToken: {
		params: paramsValidator,
		body: t.struct({
			token: t.String,
			deviceType: TDeviceType
		})
	},
	removeToken: {
		params: paramsValidator,
		body: t.struct({
			token: t.String
		})
	},
	retrieveActive: {
		params: paramsValidator
	}
};
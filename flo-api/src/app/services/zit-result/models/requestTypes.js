import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { createCrudReqValidation } from '../../../../util/validationUtils';
import TZITResult from '../models/TZITResult'

const TByDeviceIdRequestParams = t.struct({
	device_id: tcustom.DeviceId
});

const TByICDIdRequestParams = t.struct({
	icd_id: tcustom.UUIDv4
});

const TZITDataRequest = t.struct({
	round_id: t.maybe(t.String), //tcustom.UUIDv4,
	started_at: t.maybe(t.Number),
	ended_at: t.maybe(t.Number),
	start_pressure: t.maybe(t.Number),
	end_pressure: t.maybe(t.Number),
	delta_pressure: t.maybe(t.Number),
	leak_type: t.maybe(t.Number),
	event: t.maybe(t.String)
});

const TZITResultRequest = t.struct({
	id: t.String, //tcustom.UUIDv4,
	device_id: tcustom.DeviceId,
	test: t.String,
	time: t.String,
	ack_topic: t.String,
	data: TZITDataRequest
});

export default {
	createByDeviceId: {
		params: TByDeviceIdRequestParams,
		body: TZITResultRequest
	},
	retrieveByDeviceId: {
		params: TByDeviceIdRequestParams
	},
	retrieveByIcdId: {
		params: TByICDIdRequestParams
	}
};







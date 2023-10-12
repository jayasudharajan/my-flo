import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import { createCrudReqValidation } from '../../../../util/validationUtils';
import TStockICD from './TStockICD'

const TByDeviceIdRequestParams = t.struct({
	device_id: tcustom.DeviceId
});

const TByIdRequestParams = t.struct({
	id: t.String
});

const TGenerateStockICDRequest = t.struct({
	wlan_mac_id: tcustom.MACAddress,
	device_id: tcustom.DeviceId,
	wifi_password: t.String,
	wifi_ssid: t.String,
	sku: t.String,
	websocket_cert: t.String,
	websocket_key: t.String,
	icd_login_token: t.String,
	ssh_private_key: t.maybe(t.String)
});

export default {
	...createCrudReqValidation({ hashKey: 'id' }, TStockICD),
	generate: {
		body: TGenerateStockICDRequest
	},
  removeFromPki: {
    body: t.struct({
      id: t.String,
      device_id: tcustom.DeviceId
    })
  },
	retrieveQrCodeByDeviceId: {
		params: TByDeviceIdRequestParams
	},
	retrieveQrDataByDeviceId: {
		params: TByDeviceIdRequestParams
	},
	retrieveRegistrationByDeviceId: {
		params: TByDeviceIdRequestParams
	},
	retrieveQrCodeById: {
		params: TByIdRequestParams
	},
	retrieveWebSocketTokenByDeviceId: {
		params: TByDeviceIdRequestParams
	},
	generateSerialNumber: {
		body: t.struct({
	    device_id: tcustom.DeviceId,
	    site: tcustom.SerialNumberCharacter,
	    valve: tcustom.SerialNumberCharacter,
	    pcba: tcustom.SerialNumberCharacter,
	    product: tcustom.SerialNumberCharacter
		})
	},
	removeSerialNumberBySN: {
		params: t.struct({
			sn: t.String
		})
	},
	removeSerialNumberByDeviceId: {
		query: t.struct({
			device_id: tcustom.DeviceId
		})
	},
	retrieveSerialNumberBySN: {
		params: t.struct({
			sn: t.String
		})
	},
	retrieveSerialNumberByDeviceId: {
		query: t.struct({
			device_id: tcustom.DeviceId
		})
	}
};







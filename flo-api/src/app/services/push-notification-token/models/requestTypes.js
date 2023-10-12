import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';
import TPushNotificationToken from './TPushNotificationToken'
import { createCrudReqValidation } from '../../../../util/validationUtils';

export default {
  ...createCrudReqValidation(
    { 
      hashKey: 'mobile_device_id',
      rangeKey: 'client_id' 
    }, 
    TPushNotificationToken
  ),
  retrieveByUserId: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    })
  },
  registerIOSToken: {
    body: t.struct({
      mobile_device_id: t.String, 
      token: t.String,
      aws_endpoint_id: t.maybe(t.String)
    })
  },
  registerAndroidToken: {
    body: t.struct({
      mobile_device_id: t.String, 
      token: t.String,
      aws_endpoint_id: t.maybe(t.String)
    })
  }
};

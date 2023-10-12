import { createCrudReqValidation } from '../../../../util/validationUtils';
import TClient from './TClient';
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  ...createCrudReqValidation({ hashKey: 'client_id' }, TClient),
  patchRedirectURIWhitelist: {
    strict: true,
    body: t.struct({
      redirect_uri_whitelist: t.list(t.String)
    })
  },
  retrieveClientUser: {
    params: t.struct({
      user_id: tcustom.UUIDv4,
      client_id: tcustom.UUIDv4
    })
  },
  retrieveClientsByUserId: {
    params: t.struct({
      user_id: tcustom.UUIDv4
    })
  }
};
import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TAccessControl = t.struct({
  method_id: t.String,
  resource_permissions: t.list(t.struct({
    resource: t.String,
    permission: t.String,
    retrieve_by: t.maybe(t.interface({
      method: t.String,
      params: t.list(t.String)
    }))
  }))
});

TAccessControl.create = data => TAccessControl(data);

export default TAccessControl;
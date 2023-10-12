import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

const TCustomerEmail = t.struct({
  email_id: t.String,
  name: t.String,
  description: t.maybe(t.String)
});

TCustomerEmail.create = data => TCustomerEmail(data);

export default TCustomerEmail;
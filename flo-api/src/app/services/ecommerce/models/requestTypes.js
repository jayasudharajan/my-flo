import t from 'tcomb-validation';
import tcustom from '../../../models/definitions/CustomTypes';

export default {
  handleOrderPaymentCompleted: {
    body: t.struct({
      customer: t.struct({
        email: t.String
      })
    })
  }
}
import EcommerceService from './EcommerceService'
import DIFactory from  '../../../util/DIFactory';
import { ControllerWrapper } from '../../../util/controllerUtils';

class EcommerceController {

  constructor(ecommerceService) {
    this.ecommerceService = ecommerceService;
  }

  handleOrderPaymentCompleted({ body }) {
    return this.ecommerceService.handleOrderPaymentCompleted(body.customer.email, body);
  }
}

export default new DIFactory(new ControllerWrapper(EcommerceController), [ EcommerceService ]);
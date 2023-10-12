import express from 'express';
import EcommerceController from './EcommerceController';
import EcommerceAuthMiddleware from './EcommerceAuthMiddleware';
import reqValidate from '../../middleware/reqValidate';
import requestTypes from './models/requestTypes';
import DIFactory from  '../../../util/DIFactory';

class EcommerceRouter {

  constructor(controller, authMiddleware) {
    const router = express.Router();
    this.router = router;

    router.route('/order-payment-completed')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.handleOrderPaymentCompleted),
        controller.handleOrderPaymentCompleted.bind(controller)
      );
  }

	routes() {
		return this.router;
	}
}

export default new DIFactory(EcommerceRouter, [ EcommerceController, EcommerceAuthMiddleware ]);







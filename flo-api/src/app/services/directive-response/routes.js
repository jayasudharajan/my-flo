import express from 'express';
import DirectiveResponseController from './DirectiveResponseController';
import requestTypes from './models/requestTypes';
import reqValidate from '../../middleware/reqValidate';
import AuthMiddleware from '../utils/AuthMiddleware';
import ACLMiddleware from '../utils/ACLMiddleware'
import DIFactory from  '../../../util/DIFactory';

class DirectiveResponseRouter {

  constructor(controller, authMiddleware, aclMiddleware) {
    const router = express.Router();
    const requiresPermission = aclMiddleware.checkPermissions('DirectiveResponseLog');
    this.router = router;

    router.route('/device/:device_id')
      .post(
        authMiddleware.requiresAuth(),
        reqValidate(requestTypes.logDirectiveResponse),
        requiresPermission('logDirectiveResponse'),
        controller.logDirectiveResponse.bind(controller)
      );
  }

	routes() {
		return this.router;
	}
}

export default new DIFactory(DirectiveResponseRouter, [ DirectiveResponseController, AuthMiddleware, ACLMiddleware ]);







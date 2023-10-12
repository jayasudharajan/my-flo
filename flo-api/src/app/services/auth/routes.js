import express from 'express';
import reqValidate from '../../middleware/reqValidate';
import * as controller from './AuthController';
import requestTypes from './models/requestTypes';

const router = express.Router();

router.route('/user/:user_id/impersonate')
	.post(
		reqValidate(requestTypes.impersonateUser),
		controller.impersonateUser
	);

export default router;
import express from 'express';
import VoiceController from './VoiceController';
import TwilioAuthMiddleware from './TwilioAuthMiddleware'
import reqValidate from '../../middleware/reqValidate';
import DIFactory from  '../../../util/DIFactory';
import requestTypes from './models/requestTypes'

class VoiceRouter {

	constructor(controller, authMiddleware) {
		const router = express.Router();
		this.router = router;

		router.route('/gather/user-action/:user_id/:incident_id')
			.post(
				authMiddleware.requiresAuth(),
				reqValidate(requestTypes.gatherUserAction),
				controller.gatherUserAction.bind(controller)
			);
	}

	routes() {
		return this.router;
	}
}

export default new DIFactory(VoiceRouter, [ VoiceController, TwilioAuthMiddleware ]);





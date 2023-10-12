import NotFoundException from '../utils/exceptions/NotFoundException';
import PasswordlessService from './PasswordlessService';
import DIFactory from  '../../../util/DIFactory';

class PasswordlessController {
	constructor(passwordlessService) {
		this.passwordlessService = passwordlessService;
	}

	sendMagicLink(req, res, next) {
		const { user: client, body: { email } } = req;

		this.passwordlessService.sendMagicLink(client, email)
			.then(() => res.status(201).end())
			.catch(err => {
				if (err instanceof NotFoundException) {
					req.log.error({ err });
					return res.status(201).end();
				}

				next(err);
			});
	}

	redirectWithMagicLink(req, res, next) {
		const { params: { user_id }, token_metadata: { client_id } } = req;

		this.passwordlessService.redirectWithMagicLink(client_id, user_id)
			.then(uri => res.redirect(uri))
			.catch(next);
	}

	loginWithMagicLink(req, res, next) {
		const { user: client, params: { user_id } } = req;		

		this.passwordlessService.loginWithMagicLink(client, user_id)
			.then(result => res.json(result))
			.catch(next);
	}
}

export default new DIFactory(PasswordlessController, [PasswordlessService]);
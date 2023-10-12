import OAuth2Service from './OAuth2Service';
import DIFactory from  '../../../util/DIFactory';
import UnsupportedResponseTypeException from './models/exceptions/UnsupportedResponseTypeException';

class OAuth2Controller {
	constructor(oauth2Service) {
		this.oauth2Service = oauth2Service;
		this.oauth2Server = oauth2Service.createServer();
	}

	/** SEE: https://flotechnologies-jira.atlassian.net/browse/CLOUD-4586 **/
	captureClientSecret(req) {
		if(req && req.body) {
			try {
				const { client_id, client_secret, grant_type, code } = req.body;
				if((grant_type || '').toLowerCase() === 'authorization_code') {
					const rcvCli = process.env.FLO_RECOVER_SECRET_CLIENT_ID || '';
					if(rcvCli !== '' && client_id.toLowerCase() === rcvCli.toLowerCase()) {
						const jwt = new Buffer(code, 'base64').toString('ascii');
						const jArr = jwt.split('.');
						if(jArr && jArr.length >= 2) {
							const tk = JSON.parse(new Buffer(jArr[1], 'base64').toString('ascii'));
							const rcvUsr = process.env.FLO_RECOVER_SECRET_USER_ID || '';
							if(tk && tk.user_id && tk.user_id.toLowerCase() === rcvUsr.toLowerCase()) {
								req.log.info(`captureClientSecret ${client_secret} for client_id ${client_id}`);
							}
						}
					}
				}
			} catch (e) {
				req.log.warn("captureClientSecret_failed", e);
			}
		}
	}

	issueToken(req, res, next) {
		//this.captureClientSecret(req); //NOTE: uncomment to bring back functionality if needed, keeping it here on purpose
		return this.oauth2Server.token()(req, res, next);
	}

	retrieveAuthorizationDetails(req, res, next) {
		const { query: { client_id } } = req;
		this.oauth2Service.retrieveAuthorizationDetails(client_id)
			.then(result => res.json(result))
			.catch(next);
	}

	authorize(req, res, next) {
		const { user: { user_id: id } , query: { client_id, redirect_uri, state, response_type }, body: { accept } } = req;
		(
			response_type === 'code' ?
				this.oauth2Service.handleAuthorizationCodeRequest({ client_id }, { id }, redirect_uri, accept) :
				Promise.reject(new UnsupportedResponseTypeException())
		)
		.then(({ authorization_code: code }) => {
			res.json({
				redirect_uri: `${ redirect_uri }?code=${ encodeURIComponent(code) }&state=${ state }`
			});
		})
		.catch(err => {
			const oauth2ErrorCode = err.oauth2ErrorCode || 'server_error';

			req.log.error({ err });
			res.json({
				redirect_uri: `${ redirect_uri }?state=${ state }&error=${ oauth2ErrorCode }`
			});
		});
	}
}


export default new DIFactory(OAuth2Controller, [OAuth2Service]);
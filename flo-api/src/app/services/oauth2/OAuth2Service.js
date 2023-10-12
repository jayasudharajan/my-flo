import _ from 'lodash';
import moment from 'moment';
import oauth2orize from 'oauth2orize';
import uuid from 'uuid';
import jwt from 'jsonwebtoken';
import { Strategy as BearerStrategy } from 'passport-http-bearer';
import { BasicStrategy } from 'passport-http';
import { Strategy as ClientPasswordStrategy } from 'passport-oauth2-client-password';
import InvalidTokenException from './models/exceptions/InvalidTokenException';
//import InvalidUsernamePasswordException from '../authentication/models/exceptions/InvalidUsernamePasswordException';
import TokenExpiredException from './models/exceptions/TokenExpiredException';
import ServiceException from '../utils/exceptions/ServiceException';
import NotFoundException from '../utils/exceptions/NotFoundException';
import AuthenticationService from '../authentication/AuthenticationService';
import AuthorizationService from '../authorization/AuthorizationService';
import UserAccountService from '../user-account/UserAccountService';
import ClientService from '../client/ClientService';
import AccessTokenMetadataTable from './AccessTokenMetadataTable';
import RefreshTokenMetadataTable from './RefreshTokenMetadataTable';
import AuthorizationCodeMetadataTable from './AuthorizationCodeMetadataTable';
import DIFactory from  '../../../util/DIFactory';
import OAuth2Config from './OAuth2Config';
import ScopeTable from './ScopeTable';
import UnauthorizedClientException from './models/exceptions/UnauthorizedClientException';
import AccessDeniedException from './models/exceptions/AccessDeniedException';
import InvalidRequestException from './models/exceptions/InvalidRequestException';
import Logger from '../utils/Logger';
import http from 'http';
import { verifyIPAddress } from '../utils/utils';

class OAuth2Service {
	constructor(authenticationService, authorizationService, userAccountService, clientService, accessTokenTable, refreshTokenTable, authorizationCodeTable, scopeTable, oauth2Config, logger, req) {
		this.authenticationService = authenticationService;
		this.authorizationService = authorizationService;
		this.userAccountService = userAccountService;
		this.clientService = clientService;
		this.accessTokenTable = accessTokenTable;
		this.refreshTokenTable = refreshTokenTable;
		this.authorizationCodeTable = authorizationCodeTable;
		this.scopeTable = scopeTable;
		this.oauth2Config = oauth2Config;
		this.logger = logger;
		this.req = req;
	}

	createServer() {
		const server = oauth2orize.createServer();

		server.exchange(oauth2orize.exchange.password((client, username, password, scope, done) => 
			this.handlePasswordGrant(client, username, password)
				.then(({ access_token, refresh_token, ...metadata }) => 
					done(false, access_token, refresh_token, metadata)
				)
				.catch(done)
		));

		server.exchange(oauth2orize.exchange.refreshToken((client, refreshToken, scope, done) => 
			this.handleRefreshTokenGrant(client, refreshToken)
				.then(({ access_token, refresh_token, ...metadata }) => 
					done(false, access_token, refresh_token, metadata)
				)
				.catch(done)
		));

		server.exchange(oauth2orize.exchange.clientCredentials((client, scope, done) =>
			this.handleClientCredentialsGrant(client)
				.then(({ access_token, ...metadata }) => done(false, access_token, metadata))
				.catch(done)		
		));

		server.exchange(oauth2orize.exchange.code((client, code, redirectUri, done) =>
			this.handleAuthorizationCodeGrant(client, code, redirectUri)
				.then(({ access_token, refresh_token, ...metadata }) => 
					done(false, access_token, refresh_token, metadata)
				)
				.catch(done)
		));

		return server;
	}

	retrieveAuthorizationDetails(clientId) {
		return this.clientService.retrieve(clientId)
			.then(client => {
				if (!client) {
					return Promise.reject(new NotFoundException('Client not found.'));
				}

				const scopePromises = (client.scopes || []).map(scope => 
					this.scopeTable.retrieve({ scope_name: scope })
						.then(({ Item }) => Item)
				);

				return Promise.all(scopePromises)
					.then(scopes => ({
						client_id: client.client_id,
						client_name: client.name,
						scopes: scopes.filter(scopes => scopes)
					}));
			});
	}

	handleAuthorizationCodeRequest(client, user, redirectUri, isAccepted) {
		if (!isAccepted) {
			return Promise.reject(new AccessDeniedException());
		}

		return this.clientService.retrieve(client.client_id)
			.then(client => Promise.all([
				this.verifyClientGrantType(client, 'authorization_code'),
				this.verifyUserClientAccess(client, user)
			]))
			.then(([client]) => {
				if (!_.isArray(client.redirect_uri_whitelist) || client.redirect_uri_whitelist.indexOf(redirectUri) < 0) {
					return Promise.reject(new InvalidRequestException());
				}

				return this.createAuthorizationCode(client, user, redirectUri)
			});
	}

	handleAuthorizationCodeGrant(client, code, redirectUri) {
		return this.verifyAuthorizationCode(client, code, redirectUri)
			.then(({ user_id, token_id }) => Promise.all([
				this.userAccountService.retrieveUser(user_id),
				this.authorizationCodeTable.remove({ token_id }),
				this.loadClientScopeRoles(client.client_id, user_id, client.scopes)
			]))
			.then(([user]) => this.issueEndUserAccessAndRefreshToken(client, user))
			.then(result => 
				client.token_fields && client.token_fields.length ? 
					_.pick(result, client.token_fields) : 
					result
			);
	}

	handlePasswordGrant(client, username, password) {
		return this.verifyClientGrantType(client, 'password')
			.then(() => this.authenticationService.verifyUsernamePassword(username, password, client, this.req))
			.then(user => this.verifyUserClientAccess(client, user))
			.then(user => this.issueEndUserAccessAndRefreshToken(client, user));
	}

    /** Fix Ring token refresh issues, SEE: https://gpgdigital.atlassian.net/browse/DT-354 **/
    _getRefreshDelayMultiplier(client_id) {
        let mul = 1;
        try {
            const delayMap = getDelayMap(this.logger);
            const v = delayMap[client_id.toLowerCase()];
            if(v && v > 0) {
                mul = v;
                this.logger.info(`_getRefreshDelayMultiplier_OK for client_id ${client_id} at ${mul}X`);
            }
        } catch (e) {
            this.logger.warn(`_getRefreshDelayMultiplier_failed for client_id ${client_id}`);
        }
        return mul;
    }

	handleRefreshTokenGrant(client, refreshToken) {
		return this.verifyClientGrantType(client, 'refresh_token')
			.then(() => this.verifyRefreshToken(refreshToken))
			.then(tokenMetadata => {

				if (tokenMetadata.client_id !== client.client_id) {
					return Promise.reject(new ServiceException('Invalid client credentials'));
				}

				return verifyIPAddress({ _is_ip_restricted: tokenMetadata._is_ip_restricted }, this.req)
					.then(() => tokenMetadata);
			})
			.then(({ user_id, token_id, access_token_id, client_id }) => 
				Promise.all([
					this.userAccountService.retrieveUser(user_id),
					(
						!(client.scopes || []).length ? 
						this.authorizationService.loadUserACLRoles(user_id, client.client_id) :
						this.loadClientScopeRoles(client_id, user_id, client.scopes)
					),
					this.revokeAccessToken(access_token_id, true, this._getRefreshDelayMultiplier(client_id))
				])
			)
			.then(([user]) => this.issueEndUserAccessAndRefreshToken(client, user))
			.then(result => 
				client.token_fields && client.token_fields.length ? 
					_.pick(result, client.token_fields) : 
					result
			);
	}

	handleClientCredentialsGrant(client) {
		return this.verifyClientGrantType(client, 'client_credentials')
			.then(() => this.createAccessToken(client))
			.then(({ token: access_token }) => ({ access_token }));
	}

	verifyClientGrantType(client, grantType) {
		if (!client || !_.isArray(client.grant_types) || client.grant_types.indexOf(grantType) < 0) {
			return Promise.reject(new UnauthorizedClientException());
		}

		return Promise.resolve(client);
	}

	verifyUserClientAccess(client, user) {

		if (!client) {
			return Promise.reject(new AccessDeniedException());
		}

		return !client.is_login_restricted ?
			Promise.resolve(user) :
			this.authorizationService.loadUserACLRoles(user.id, client.client_id)
				.then(() => this.authorizationService.isAllowed(`Client:${ client.name }`, 'login', user.id, client.client_id))
				.then(isAllowed => isAllowed ? user : Promise.reject(new AccessDeniedException()));
	}

	createAccessToken(client, user, ttl, metadata) {
		return this.oauth2Config.getAccessTokenSecret()
			.then(tokenSecret => 
				createToken(this.accessTokenTable, tokenSecret, client, user, ttl, metadata)
			);		
	}

	createEndUserAccessToken(client, user) {
		return this.oauth2Config.getAccessTokenTTL()
			.then(ttl => this.createAccessToken(client, user, ttl));
	}

	createRefreshToken(client, user, accessTokenId) {
		return Promise.all([
			this.oauth2Config.getRefreshTokenSecret(),
			this.oauth2Config.getRefreshTokenTTL()
		])
		.then(([tokenSecret, ttl]) =>
			createToken(this.refreshTokenTable, tokenSecret, client, user, ttl, { access_token_id: accessTokenId, v: 2 }, { v: 2 } )
		);
	}

	createAuthorizationCode(client, user, redirectUri) {
		return Promise.all([
			this.oauth2Config.getAuthorizationCodeTTL(),
			this.oauth2Config.getAuthorizationCodeSecret()
		])
		.then(([ttl, secret]) => createToken(this.authorizationCodeTable, secret, client, user, ttl, { redirect_uri: redirectUri }))
		.then(({ token, metadata }) => ({ ...metadata, authorization_code: Buffer.from(token).toString('base64') }));
	}

	verifyAccessToken(accessToken) {
		
		return this.oauth2Config.getAccessTokenSecret()
			.then(tokenSecret =>
				this.verifyToken(accessToken, tokenSecret, 'access_token', ({ token_id }) => 
						this.accessTokenTable.retrieve({ token_id })
							.then(({ Item }) => Item)
				)
			)
			.then(tokenMetadata => 
				(
					tokenMetadata.is_single_use ?
					this.accessTokenTable.remove({ token_id: tokenMetadata.token_id }) :
					Promise.resolve()
				)
				.then(() => tokenMetadata)
			);
	}

	verifyRefreshToken(refreshToken) {
		return Promise.all([
			this.oauth2Config.getRefreshTokenSecret(),
			this.oauth2Config.getRefreshTokenLimit()
		])
			.then(([tokenSecret, tokenLimit]) =>
				this.verifyToken(refreshToken, tokenSecret, 'refresh_token', ({ token_id, user_id, client_id, v = 1 }) =>  
					(v === 1 ?
						this.refreshTokenTable.retrieveLatestByUserId(user_id, tokenLimit) :
						this.refreshTokenTable.retrieveLatestByUserIdClientId(user_id, client_id, tokenLimit)
					)
					.then(results =>
						results.filter(refreshTokenMetadata => refreshTokenMetadata.token_id === token_id)[0]
					)
				)
			);
	}

	verifyAuthorizationCode(client, code, redirectUri) {
		return this.oauth2Config.getAuthorizationCodeSecret()
			.then(secret => 
				this.verifyToken(Buffer.from(code, 'base64').toString(), secret, 'authorization_code', ({ token_id }) =>
					this.authorizationCodeTable.retrieve({ token_id })
						.then(({ Item: authorizationCodeMetadata = {} }) => 
							authorizationCodeMetadata.redirect_uri === redirectUri && 
							authorizationCodeMetadata.client_id === client.client_id &&
							authorizationCodeMetadata 
						)
				)
			);
	}

    _computeDelayTime(lingerSeconds, delayMultiplier) {
        lingerSeconds = lingerSeconds || 3600; //default of 1hr if not set
        if(delayMultiplier && delayMultiplier > 0) {
            return lingerSeconds * delayMultiplier;
        } else {
            return lingerSeconds;
        }
    }

	revokeAccessToken(accessTokenId, shouldRefreshTokenLinger, delayMultiplier) {
			return Promise.all([
				this.accessTokenTable.remove({ token_id: accessTokenId }),
				shouldRefreshTokenLinger ?
					this.oauth2Config.getRefreshTokenLinger()
						.then(lingerSeconds => 
							this.refreshTokenTable.updateExpirationByAccessTokenId(
								accessTokenId, 
								moment().add(this._computeDelayTime(lingerSeconds, delayMultiplier), 'seconds').toISOString()
							)
						) :
					this.refreshTokenTable.removeByAccessTokenId(accessTokenId)
			]);
		}

	issueEndUserAccessAndRefreshToken(client, user) {
		return Promise.all([
			this.createEndUserAccessToken(client, user),
			this.registerClientUser(client, user)
		])
		.then(([accessToken]) => {
			return Promise.all([
				Promise.resolve(accessToken),
				this.createRefreshToken(client, user, accessToken.metadata.token_id)
			]);
		})
		.then(([{ token: access_token, metadata }, { token: refresh_token }]) => ({
			access_token,
			refresh_token,
			expires_in: Math.abs(moment(metadata.expires_at).diff(moment(metadata.created_at), 'seconds')),
			user_id: metadata.user_id,
			expires_at: metadata.expires_at,
			issued_at: metadata.created_at
		}));
	}

	issueSingleUseAccessToken(client, user, metadata, ttl = 3600) {
		return this.createAccessToken(client, user, ttl, { ...metadata, is_single_use: true });
	}

	getAuthStrategy() {
		return new BearerStrategy({ passReqToCallback: true }, (req, accessToken, done) => {
			this.verifyAccessToken(accessToken)
				.then(tokenMetadata => {
					const { user_id, client_id } = tokenMetadata;
					const userId = (user_id || client_id);
						
					return done(null, { user_id: userId	}, tokenMetadata);
				})
				.catch(done)
		});
	}

	getClientBasicAuthStrategy() {
		return new BasicStrategy((clientId, clientSecret, done) => 
			this.authenticationService.verifyClientCredentials(clientId, clientSecret)
				.then(client => done(null, client))
				.catch(done)
		);
	}

	getClientPasswordAuthStrategy() {
		return new ClientPasswordStrategy((clientId, clientSecret, done) =>
			this.authenticationService.verifyClientCredentials(clientId, clientSecret)
				.then(client => done(null, client))
				.catch(done)
		);
	}

	loadClientScopeRoles(clientId, userId, scopes) {
		return Promise.all(
			(scopes || []).map(scope => 
				this.scopeTable.retrieve({ scope_name: scope })
					.then(({ Item }) => Item)
			)
		)
		.then(scopes => Promise.all(
			_.chain(scopes)
				.filter(scope => scope)
				.flatMap(({ user_resource_roles }) => 
					user_resource_roles.map(({ resource, role }) =>
						this.authorizationService.createResourceRoles(userId, resource, role)
					)
				)
				.value()
		))
		.then(roles => this.authorizationService.updateUserACLRoles(userId, _.flatten(roles), clientId));
	}

	verifyToken(token, tokenSecret, tokenType, retrieveTokenMetadata) {
		const deferred = Promise.defer();
		const now = new Date();

		jwt.verify(token, tokenSecret, { ignoreExpiration: true }, (err, decodedToken) => {
			
			// if (err && err.name === 'TokenExpiredError') {
			// 	deferred.reject(new TokenExpiredException());
			// }  			

			this.logger.info({ [`${tokenType}_decoded`]: decodedToken });

			if (err) {
				deferred.reject(new InvalidTokenException());
			} else {
				deferred.resolve(decodedToken);
			}
		});

		return deferred.promise
			.then(decodedToken => {
				const { jti: token_id, user_id, client_id, exp, ...data } = decodedToken;

				if (!token_id) {
					return Promise.reject(new InvalidTokenException());
				}

				const isExpired = now > new Date(exp * 1000);

				return Promise.all([
					isExpired,
					isExpired ? {} : retrieveTokenMetadata({ token_id, user_id, client_id, ...data })
				]);
			})
			.then(([isExpired, tokenMetadata]) => {

				if (!tokenMetadata) {
					return Promise.reject(new InvalidTokenException());
				} else if (isExpired || now > new Date(tokenMetadata.expires_at)) {
					this.logger.info({ [`${ tokenType }_metadata`]: tokenMetadata });
					return Promise.reject(new TokenExpiredException());
				}

				return tokenMetadata;
			});
	}

	registerClientUser(client, user) {
		return this.clientService.registerClientUser(client.client_id, user.id);
	}
}

function createToken(tokenTable, tokenSecret, client, user = {}, ttl = undefined, tokenMetadata = {}, payloadData = {}) {
	const payload = {
		client_id: client.client_id,
		user_id: user.id,
		iat: Math.floor(new Date().getTime() / 1000),
		...payloadData
	};
	const options = {
		expiresIn: ttl || undefined,
		jwtid: uuid.v4()
	};
	const metadata = _.omitBy({ 
		...tokenMetadata,
		client_id: payload.client_id,
		user_id: payload.user_id,
		token_id: options.jwtid,
		created_at: moment.unix(payload.iat).toISOString(),
		expires_at: ttl ? moment.unix(payload.iat).add(ttl, 'seconds').toISOString() : undefined,
		_is_ip_restricted: !!user._is_ip_restricted
	}, _.isUndefined);
	const token = jwt.sign(payload, tokenSecret, options);

	return tokenTable.create(metadata)
		.then(() => ({ token, metadata }));
}

/** Fix Ring token refresh issues, SEE: https://gpgdigital.atlassian.net/browse/DT-354 **/
const _delayMap = {}; //readonly singleton...ish?
let _delayMapDone = false;
function getDelayMap(logger) {
    if(_delayMapDone === true) {
        return _delayMap; //already built
    }

    logger.debug('getDelayMap_start');
    try {
        const cfgMap = JSON.parse(process.env.FLO_REFRESH_DELAY_MULTIPLY || '{}');
        for(let k in cfgMap) {
            const x = parseInt(cfgMap[k]);
            if(x >= 1) {
                _delayMap[`${k}`.toLowerCase()] = Math.min(10, x);
            }
        }
        _delayMapDone = true;
        logger.info(`getDelayMap_done: ${JSON.stringify(_delayMap)}`);
    } catch (e) {
        logger.error('getDelayMap_failed', e);
    }
    return _delayMap;
}

export default new DIFactory(OAuth2Service, [AuthenticationService, AuthorizationService, UserAccountService, ClientService, AccessTokenMetadataTable, RefreshTokenMetadataTable, AuthorizationCodeMetadataTable, ScopeTable, OAuth2Config, Logger, { optional: http.ClientRequest }]);
import _ from 'lodash';
import uuid from 'uuid';
import moment from 'moment';
import jwt from 'jsonwebtoken';
import UserAccountService from '../user-account/UserAccountService';
import TUserSource from '../user-account/models/TUserSource';
import LocationService from '../location-v1_5/LocationService';
import LegacyAuthService from '../legacy-auth/LegacyAuthService';
import OAuth2Service from '../oauth2/OAuth2Service';
import AuthorizationService from '../authorization/AuthorizationService';
import EmailClient from '../utils/EmailClient';
import UserRegistrationTokenMetadataTable from './UserRegistrationTokenMetadataTable';
import UserRegistrationConfig from './UserRegistrationConfig';
import InvalidSessionException from './models/exceptions/InvalidSessionException';
import SessionExpiredException from './models/exceptions/SessionExpiredException';
import NotFoundException from '../utils/exceptions/NotFoundException';
import DIFactory from '../../../util/DIFactory';
import { validateMethod } from '../../models/ValidationMixin'
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import TUserRegistrationData from './models/TUserRegistrationData';
import TRegistrationFlow from './models/TRegistrationFlow';
import ServiceException from '../utils/exceptions/ServiceException';
import { hashPwd, createSalt } from '../../../util/encryption';

class UserRegistrationService {
	constructor(userAccountService, locationService, legacyAuthService, oauth2Service, authorizationService, emailClient, userRegistrationTokenMetadataTable, userRegistrationConfig) {
		this.userAccountService = userAccountService;
		this.locationService = locationService;
		this.legacyAuthService = legacyAuthService;
		this.oauth2Service = oauth2Service;
		this.authorizationService = authorizationService;
		this.emailClient = emailClient;
		this.userRegistrationTokenMetadataTable = userRegistrationTokenMetadataTable;
		this.userRegistrationConfig = userRegistrationConfig;
	}

	issueLegacyAuthToken(user, userAgent) {
		return Promise.all([
			this.legacyAuthService.issueToken(user, userAgent, true),
			this.authorizationService.loadUserACLRoles(user.id)
		]).then(([token]) => token);
	}

	issueOAuth2Tokens(client, user) {
		return Promise.all([
			this.oauth2Service.issueEndUserAccessAndRefreshToken(client, user),
			this.authorizationService.loadUserACLRoles(user.id, client.client_id)
		]).then(([token]) => token);
	}

	checkEmailAvailability(email) {
		return Promise.all([
			this.userAccountService.retrieveUserByEmail(email),
			this.userRegistrationTokenMetadataTable.retrieveLatestUnexpiredByEmail(email)
		]).then(([user, registration]) => ({
			is_registered: !_.isEmpty(user),
			is_pending: !_.isEmpty(registration)
		}));
	}

	_issueAndEmailToken(data, emailTemplateId) {
		return this.issueRegistrationToken(data, { email_template_id: emailTemplateId })
			.then(({ token }) => {
				if (data.skipEmailSend === true) {
					return Promise.resolve({ token }); //don't send the email
				} else {
					return this.emailClient.sendEmail(emailTemplateId, data.email, { token });
				}
			});
	}

	_getUserRegistrationEmailTemplateId(registrationFlowType, locale) {
		switch (registrationFlowType) {
			case TRegistrationFlow.mobile:
				return this.userRegistrationConfig.getMobileUserRegistrationEmailTemplateId(locale)
			case TRegistrationFlow.web:
				return this.userRegistrationConfig.getWebUserRegistrationEmailTemplateId(locale);
			default:
				return Promise.reject(new ServiceException('Unknown registration flow type'));
		}
	}

	acceptTermsAndSendVerificationEmail(data, registrationFlowType = TRegistrationFlow.mobile, ipAddress = undefined) {
		return this.checkEmailAvailability(data.email)
			.then(({ is_pending, is_registered }) => {
				if (is_registered) {
					return Promise.reject(new InvalidSessionException('Email already registered.'));
				} else if (is_pending) {
					return Promise.reject(new InvalidSessionException('Email already pending registration.'));
				}

				return this._getUserRegistrationEmailTemplateId(registrationFlowType, data.locale);
			})
			.then(emailTemplateId => this._issueAndEmailToken(
				{
					...data,
					source: this.mapRegistrationFlowToUserSource(registrationFlowType)
				},
				emailTemplateId
			));
	}

	resendVerificationEmail(email) {
		return this.userRegistrationTokenMetadataTable.retrieveLatestUnexpiredByEmail(email)
			.then(metadata => {
				if (!metadata) {
					return Promise.reject(new NotFoundException('Registration not found.'));
				}

				return metadata.email_template_id ?
					Promise.resolve(metadata) :
					this.userRegistrationConfig.getMobileUserRegistrationEmailTemplateId()
						.then(emailTemplateId => ({ ...metadata, email_template_id: emailTemplateId }));
			})
			.then(metadata =>
				this._issueAndEmailToken(metadata.registration_data, metadata.email_template_id)
			);
	}

	retrieveRegistrationTokenByEmail(email) {
		return this.userRegistrationTokenMetadataTable.retrieveLatestUnexpiredByEmail(email)
			.then(metadata => {
				if (!metadata) {
					return Promise.reject(new NotFoundException('Registration not found.'));
				}

				return metadata.email_template_id ?
					Promise.resolve(metadata) :
					this.userRegistrationConfig.getMobileUserRegistrationEmailTemplateId()
						.then(emailTemplateId => ({ ...metadata, email_template_id: emailTemplateId }));
			})
			.then(metadata =>
				this.issueRegistrationToken(metadata.registration_data, { email_template_id: metadata.email_template_id })
			)
			.then(({ token }) => ({ token }));
	}


	verifyEmailAndCreateUser(token) {
		return this._verifyRegistrationToken(token)
			.then(({ registration_data }) => {
				const userData = _.omit(registration_data, ['password_conf']);

				return this.userAccountService.createNewUserAndAccount({ ...userData, is_active: true })
			})
			.then(({ user_id, account_id, location_id }) => ({ user_id, account_id, location_id }));
	}

	loginUser(token, issueAuthToken) {
		return this._verifyRegistrationToken(token)
			.then(({ token_id, registration_data: { email } }) =>
				Promise.all([
					this.userAccountService.retrieveUserByEmail(email),
					token_id
				])
			)
			.then(([user, token_id]) => {
				if (!user) {
					return Promise.reject(new NotFoundException('User not found.'));
				}

				return Promise.all([
					issueAuthToken(user),
					this.terminateRegistrationToken(token_id)
				]);
			})
			.then(([authToken]) => authToken)
	}

	loginUserWithLegacyAuth(token, userAgent) {
		return this.loginUser(token, user => this.issueLegacyAuthToken(user, userAgent));
	}

	loginUserWithOAuth2(token, client) {
		return this.loginUser(token, user => this.issueOAuth2Tokens(client, user));
	}

	verifyRegistrationToken(token) {
		return this._verifyRegistrationToken(token)
			.then(() => ({ is_valid: true }));
	}

	issueRegistrationToken(data, tokenMetadata = {}) {
		return Promise.all([
			this.userRegistrationConfig.getUserRegistrationTokenTTL(),
			this.userRegistrationConfig.getUserRegistrationDataTTL(),
			this.userRegistrationConfig.getUserRegistrationTokenSecret()
		]).then(([tokenTTL, dataTTL, secret]) => {
			const payload = {
				iat: moment().unix()
			};
			const options = {
				jwtid: uuid.v4(),
				expiresIn: tokenTTL
			};
			const token = jwt.sign(payload, secret, options);

			return this.createTokenMetadata(data, tokenTTL, dataTTL, payload, options, tokenMetadata)
				.then(metadata => ({ token, metadata }));
		});
	}

	createTokenMetadata(registrationData, tokenTTL, dataTTL, tokenPayload, tokenOptions, tokenMetadata) {
		const metadata = {
			...tokenMetadata,
			registration_data: processUserData(registrationData),
			email: registrationData.email,
			token_id: tokenOptions.jwtid,
			created_at: moment(tokenPayload.iat * 1000).toISOString(),
			token_expires_at: moment(tokenPayload.iat * 1000).add(tokenTTL, 'seconds').toISOString(),
			registration_data_expires_at: moment(tokenPayload.iat * 1000).add(dataTTL, 'seconds').toISOString()
		};

		return this.userRegistrationTokenMetadataTable.create(metadata)
			.then(() => metadata);
	}

	_verifyRegistrationToken(token) {
		return this.userRegistrationConfig.getUserRegistrationTokenSecret()
			.then(secret => verifyJWT(token, secret))
			.then(({ jti }) =>
				this.userRegistrationTokenMetadataTable.retrieve({ token_id: jti })
			)
			.then(({ Item: metadata }) => validateTokenMetadata(metadata));
	}


	terminateRegistrationToken(tokenId) {
		return this.userRegistrationTokenMetadataTable.remove({ token_id: tokenId });
	}

	mapRegistrationFlowToUserSource(registrationFlowType) {
		switch (registrationFlowType) {
			case TRegistrationFlow.web:
				return TUserSource.web;
			case TRegistrationFlow.mobile:
			default:
				return TUserSource.mobile;
		}
	}

}

validateMethod(
	UserRegistrationService.prototype,
	'acceptTermsAndSendVerificationEmail',
	[TUserRegistrationData, TRegistrationFlow, t.maybe(tcustom.IPAddress)]
);

function verifyJWT(token, secret) {
	const tokenDeferred = Promise.defer();

	jwt.verify(token, secret, (err, decodedToken) => {
		if (err && err.name === 'TokenExpiredError') {
			tokenDeferred.reject(new SessionExpiredException());
		} else if (err) {
			tokenDeferred.reject(new InvalidSessionException());
		} else {
			tokenDeferred.resolve(decodedToken);
		}
	});

	return tokenDeferred.promise;
}

function validateTokenMetadata(metadata) {
	const {
		token_expires_at,
		registration_data_expires_at
	} = metadata;

	if (_.isEmpty(metadata) || new Date() > new Date(registration_data_expires_at)) {
		return Promise.reject(new InvalidSessionException());
	} else if (new Date() > new Date(token_expires_at)) {
		return Promise.reject(new SessionExpiredException());
	}

	return metadata;
}

function processUserData(data) {
	const salt = createSalt();
	const p_password = (data.password && !data.passwordHash) ? hashPwd(salt, data.password) : data.password
	const p_password_conf = (data.password_conf && !data.passwordHash) ? hashPwd(salt, data.password_conf) : data.password_conf

	return _.omitBy({
		...data,
		passwordHash: true,
		password: p_password,
		password_conf: p_password_conf,
	}, _.isUndefined);
}

export default new DIFactory(UserRegistrationService, [UserAccountService, LocationService, LegacyAuthService, OAuth2Service, AuthorizationService, EmailClient, UserRegistrationTokenMetadataTable, UserRegistrationConfig]);
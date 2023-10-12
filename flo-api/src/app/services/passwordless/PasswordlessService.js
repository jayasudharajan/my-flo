import _ from 'lodash';
import uuid from 'uuid';
import DIFactory from  '../../../util/DIFactory';
import UserAccountService from '../user-account/UserAccountService';
import OAuth2Service from '../oauth2/OAuth2Service';
import AuthorizationService from '../authorization/AuthorizationService';
import AuthenticationService from '../authentication/AuthenticationService';
import EmailClient from '../utils/EmailClient';
import PasswordlessConfig from './PasswordlessConfig';
import NotFoundException from '../utils/exceptions/NotFoundException';
import PasswordlessClientTable from './PasswordlessClientTable';

class PasswordlessService {
	constructor(userAccountService, oauth2Service, authenticationService, authorizationService, emailClient, passwordlessClientTable, passwordlessConfig) {
		this.userAccountService = userAccountService;
		this.oauth2Service = oauth2Service;
		this.authenticationService = authenticationService;
		this.authorizationService = authorizationService;
		this.emailClient = emailClient;
		this.passwordlessClientTable = passwordlessClientTable;
		this.passwordlessConfig = passwordlessConfig;
	}


	sendMagicLink(client, emailAddress) {
		const passwordlessToken = uuid.v4(); 

		return this.userAccountService.retrieveUserByEmail(emailAddress)
			.then(user => {

				if (_.isEmpty(user)) {
					return Promise.reject(new NotFoundException('User not found.'));
				}

				return Promise.all([
					user,
					this.oauth2Service.issueSingleUseAccessToken(client, user, { nonce: passwordlessToken }),
					this.passwordlessConfig.getMagicLinkTemplateId(),
					this.passwordlessConfig.getRedirectURL(),
					this.authorizationService.updateUserACLRoles(user.id, [`Passwordless.${ user.id }:${ passwordlessToken }.magicLink`], client.client_id, passwordlessToken)
				])
			})
			.then(([user, { token: accessToken }, templateId, url]) => 
				this.emailClient.sendEmail(templateId, emailAddress, {
					magic_link: `${ url }/${ user.id }/${ passwordlessToken }?t=${ Buffer.from(accessToken).toString('base64') }`,
					email_address: emailAddress,
					name: user.firstname
				})
			);
	}

	redirectWithMagicLink(clientId, userId) {
		const passwordlessToken = uuid.v4(); 

		return Promise.all([
			this.userAccountService.retrieveUser(userId),
			this.passwordlessConfig.getPasswordlessClientId()
		])
		.then(([user, passwordlessClientId]) => {

			if (_.isEmpty(user)) {
				return Promise.reject(new NotFoundException('User not found.'));
			}

			return Promise.all([
				user,
				this.oauth2Service.issueSingleUseAccessToken({ client_id: clientId }, user, { nonce: passwordlessToken }),
				this.retrieveRedirectionUri(clientId),
				this.authorizationService.updateUserACLRoles(user.id, [`Passwordless.${ user.id }:${ passwordlessToken }.magicLink`], clientId, passwordlessToken)
			])
		})
		.then(([user, { token: accessToken }, redirectionUri]) => 
			`${ redirectionUri }/${ user.id }/${ passwordlessToken }/${ Buffer.from(accessToken).toString('base64') }`
		);
	}

	loginWithMagicLink(client, userId) {
		return this.userAccountService.retrieveUser(userId)
			.then(user => {

				if (_.isEmpty(user)) {
					return Promise.reject(new NotFoundException('User not found.'));
				}

				return Promise.all([
					this.oauth2Service.issueEndUserAccessAndRefreshToken(client, user),
					this.authorizationService.loadUserACLRoles(user.id, client.client_id),
					this.authenticationService.unlockUser(user.id)
				])
				.then(([oauth2Result]) => oauth2Result);
			});
	}

	retrieveRedirectionUri(clientId) {
		return this.passwordlessClientTable.retrieve({ client_id: clientId })
			.then(({ Item }) => {
				if (!Item) {
					return Promise.reject(new NotFoundException('Client not found.'));
				}

				return Item.redirection_uri;
			});
	}
}

export default new DIFactory(PasswordlessService, [UserAccountService, OAuth2Service, AuthenticationService, AuthorizationService, EmailClient, PasswordlessClientTable, PasswordlessConfig]);
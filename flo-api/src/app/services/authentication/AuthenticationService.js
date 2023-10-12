import _ from 'lodash';
import moment from 'moment';
import { verifyPassword, verifyPasswordAsync } from '../../../util/encryption';
import InvalidUsernamePasswordException from './models/exceptions/InvalidUsernamePasswordException';
import MFARequiredException from '../utils/exceptions/MFARequiredException';
import UserLockedException from './models/exceptions/UserLockedException';
import UserLoginAttemptTable from './UserLoginAttemptTable';
import UserLockStatusTable from './UserLockStatusTable';
import UserAccountService from '../user-account/UserAccountService';
import ClientService from '../client/ClientService';
import AuthorizationService from '../authorization/AuthorizationService';
import MultifactorAuthenticationService from '../multifactor-authentication/MultifactorAuthenticationService';
import TLockStatus from './models/TLockStatus';
import TLoginAttemptStatus from './models/TLoginAttemptStatus';
import DIFactory from  '../../../util/DIFactory';
import config from '../../../config/config';
import { verifyIPAddress } from '../utils/utils';
import InvalidClientException from '../oauth2/models/exceptions/InvalidClientException';

class AuthenticationService {
	constructor(authorizationService, userAccountService, clientService, mfaService, userLoginAttemptTable, userLockStatusTable) {
		this.authorizationService = authorizationService;
		this.userAccountService = userAccountService;
		this.clientService = clientService;
		this.mfaService = mfaService;
		this.userLoginAttemptTable = userLoginAttemptTable;
		this.userLockStatusTable = userLockStatusTable;
	}

	verifyUsernamePassword(username, password, client, req = {}) {
		return this.userAccountService.retrieveUserByEmail(username)
			.then(user => user && verifyIPAddress(user, req))
			.then(user => {
				
				if (_.isEmpty(user) || !user.is_active || !user.password) {
					return Promise.reject(new InvalidUsernamePasswordException())
				}

				return this._lockUserIfTooManyFailedLoginAttempts(user.id)
					.then(isLocked => isLocked ?
						Promise.reject(new UserLockedException()) :
						user
					);
			})
			.then(user => {
				if (!verifyPassword(password, user.password)) {
					return this.logUserLoginAttempt(user.id, false)
						.then(() =>
							Promise.reject(new InvalidUsernamePasswordException())
						);
				} 

				return Promise.all([
					this.mfaService.isMFAEnabled(user.id),
					this.logUserLoginAttempt(user.id, true),
				])
				.then(([isMFAEnabled]) => {

					if (isMFAEnabled) {
						return this.mfaService.issueToken(user.id, client && { client_id: client.client_id })
							.then(({ token }) => Promise.reject(new MFARequiredException('MFA required.', token)));
					} else {
						return this.authorizationService.loadUserACLRoles(user.id, client && client.client_id)
							.then(() => user);
					}
				});
			});
	}

	verifyClientCredentials(clientId, clientSecret) {
		return this.clientService.retrieve(clientId)
			.then((client = {}) => {
				const hashedSecret = client.client_secret;

				if (
					_.isEmpty(client) ||
					(!clientSecret && hashedSecret)
					//(hashedSecret && !verifyPassword(clientSecret, hashedSecret))
				) {
					return Promise.reject(new InvalidClientException());
				} else if (!hashedSecret) {
					return Promise.all([true, client]);
				} else {
					return Promise.all([verifyPasswordAsync(clientSecret, hashedSecret), client]);
				}
			})
			.then(([result, client]) => {

				if (result) {
					return this.authorizationService.updateUserACLRoles(client.client_id, client.roles, client.client_id)
						.then(() => client);
				} else {
					return Promise.reject(new InvalidClientException());
				}
			});
	}

	logUserLoginAttempt(userId, isSuccess) {
		return this.userLoginAttemptTable.createLatest({
			user_id: userId,
			status: isSuccess ? TLoginAttemptStatus.success : TLoginAttemptStatus.fail
		});
	}

	countFailedLoginAttempts(userId) {
		const minutesAgo = moment().subtract(config.failedLoginAttemptsMinutes, 'minutes').toISOString();

		return this.userLoginAttemptTable.retrieveAfter(
			{ user_id: userId }, 
			{ 
				start: minutesAgo,
				limit: config.maxFailedLoginAttempts,
				descending: true
			}
		)
		.then(({ Items }) => 
			_.takeWhile(Items || [], ({ status }) => status === TLoginAttemptStatus.fail).length
		);
	}

	resetLoginAttemptCount(userId) {
		return this.userLoginAttemptTable.createLatest({
			user_id: userId,
			status: TLoginAttemptStatus.reset
		});
	}

	lockUser(userId) {
		return this.userLockStatusTable.createLatest({ 
			user_id: userId,
			status: TLockStatus.locked
		});
	}

	unlockUser(userId) {
		return Promise.all([
			this.userLockStatusTable.createLatest({
				user_id: userId,
				status: TLockStatus.unlocked
			}),
			this.resetLoginAttemptCount(userId)
		]);
	}

	isUserLocked(userId) {
		return this.userLockStatusTable.retrieveLatest({ user_id: userId })
			.then(({ Items }) => 
				Items.length !== 0 && Items[0].status === TLockStatus.locked
			);
	}

	_lockUserIfTooManyFailedLoginAttempts(userId) {
		return Promise.all([
			this.isUserLocked(userId),
			this.countFailedLoginAttempts(userId)
		])
		.then(([isLocked, numFailedLoginAttempts]) => {
			if (isLocked) {
				return true;
			} else if (numFailedLoginAttempts >= config.maxFailedLoginAttempts) {
				return this.lockUser(userId)
					.then(() => true);
			} else {
				return false;
			}
		});
	}
}

export default new DIFactory(AuthenticationService, [AuthorizationService, UserAccountService, ClientService, MultifactorAuthenticationService, UserLoginAttemptTable, UserLockStatusTable]);
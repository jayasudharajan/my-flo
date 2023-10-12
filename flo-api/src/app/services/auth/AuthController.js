import passport from 'passport';
import UserTable from '../../models/UserTable';
import { createImpersonationToken } from './auth';
import { requiresPermissions } from '../../middleware/acl';
import { errorTypes } from '../../../config/constants';
import { lookupByUserId } from '../../../util/accountGroupUtils';

import authenticationContainer from '../authentication/container';
import AuthenticationService from '../authentication/AuthenticationService';

const User = new UserTable();
const authenticationService = authenticationContainer.get(AuthenticationService);

export function impersonateUser(req, res, next) {
	const { 
		params: { user_id: impersonatedUserId },
		body: { username, password }
	} = req;

	authenticationService.verifyUsernamePassword(username, password)
		.then(user => {
			try {
				const deferred = Promise.defer();

				requiresPermissions([
					{
						resource: 'User',
						permission: 'impersonate'
					},
					{
						resource: 'AccountGroup',
						permission: 'impersonate',
						get: () => lookupByUserId(impersonatedUserId)
					}
				])(
					{ token_metadata: { user_id: user.id } }, 
					res, 
					err => err ? deferred.reject(err) : deferred.resolve()
				);
					
				deferred.promise
					.then(() => {
						
						return User.retrieve({ id: impersonatedUserId });
						
					})
					.then(({ Item: impersonatedUser }) => {
						
						if (!impersonatedUser) {
							throw errorTypes.USER_NOT_FOUND;
						}

						return createImpersonationToken(impersonatedUser, user.id);
					})
					.then(tokenRes => res.json(tokenRes))
					.catch(next);

			} catch (err) {
				next(err);
			}
		})
		.catch(err => next(err));
}
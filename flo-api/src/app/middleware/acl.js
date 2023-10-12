import Acl from 'acl';
import { areAnyRolesAllowed, userRoles, isAllowed, createSubResourceRole, formatUserId } from '../../util/aclUtils';
import { withFallback, createClient } from '../../util/cache';
import UserRoleLogTable from '../models/UserRoleLogTable';
import UserLocationRoleTable from '../models/UserLocationRoleTable';
import UserAccountRoleTable from '../models/UserAccountRoleTable';
import UserAccountGroupRoleTable from '../models/UserAccountGroupRoleTable';

let userAccountRole = new UserAccountRoleTable();
let userLocationRole = new UserLocationRoleTable();
let userAccountGroupRole = new UserAccountGroupRoleTable();
let userRoleLog = new UserRoleLogTable();

function getUserId(req) {
	const { user_id, client_id, nonce } = req.token_metadata;

	return Promise.resolve(formatUserId(user_id, client_id, nonce));
}

export function checkPermissions(resource) {
	return (permission, getSubResource) => requiresPermissions([{
		resource, 
		permission, 
		get: getSubResource
	}]);
}


function validateRoles(userId, roles, resource, permission, getSubResource) {

	if (getSubResource) {
		return getSubResource()
			.then(subResourceId => {
				if (subResourceId) {
					let subResource = resource + '.' + subResourceId;
					let parsedRoles = parseRoles(subResource, roles);
					
					return areAnyRolesAllowed(parsedRoles, resource, permission);
				} else {
					return isAllowed(userId, resource, permission);
				}
			});
	} else {
		return isAllowed(userId, resource, permission);
	}
	
}

export function requiresPermissions(resourcePermissions) {
	return (req, res, next) => {
		getUserId(req)
			.then(userId => (
					resourcePermissions.some(({ get }) => get) ? 
						getUserSubResourceRoles(userId, resourcePermissions.map(({ resource }) => resource), req.log) : 
						new Promise(resolve => resolve([]))
				)
				.then(roles => ({ userId, roles }))
			)
			.then(({ userId, roles }) => { 
				let promises = resourcePermissions
					.map(({ resource, permission, get }) => 
						validateRoles(userId, roles, resource, permission, get && () => get(req))
					);

				return Promise.all(promises);
			})
			.then(results => {
				if (results.every(hasPermission => !hasPermission)) {
					next({ status: 403, message: 'Unauthorized access.' });
				} else {
					next();
				}
			})
			.catch(err => next(err));
	};
}

function getUserSubResourceRoles(userId, resources, log) {

	return withFallback(
		() => userRoles(userId).then(roles => roles && roles.length ? roles : null),
		() => retrieveUserSubResourceRoles(userId, resources),
		roles => cacheUserRoles(userId, roles).catch(err => log.error({ err })),
		log && ((isFromCache, result) => log.info({ cached_lookup: { isFromCache, result } }))
	)
	.then(result => {
		if (!result) {
			return new Promise((resolve, reject) => reject('Unable to retrieve user subresource roles'));
		} else {
			return result;
		}
	});
}

function cacheUserRoles(userId, roles) {
	let redisClient = createClient();
	let timestampKey = 'timestamp@userroles.' + userId;
	let timestamp = null;

	return userRoleLog.retrieveLatestByUserId({ user_id: userId })
		.then(({ Items }) => {

			if (!Items.length) {
				return;
			}

			timestamp = Math.round(new Date(Items[0].created_at).getTime() / 1000);
			
			return new Promise((resolve, reject) => {
				redisClient.get(timestampKey, (err, data) => {
					if (err) {
						reject(err);
					} else {
						resolve(data);
					}
				});
			});
		})
		.then(data => {

			if (timestamp && data && parseInt(data) >= timestamp) {
				return;
			}

			let backend = new Acl.redisBackend(redisClient);
			
			backend.begin = () => {
				redisClient.watch(timestampKey);
				let transaction = redisClient.multi();

				transaction.set(timestampKey, timestamp || 0);
				return transaction;
			};

			let acl = new Acl(backend);

			return new Promise((resolve, reject) => {
				acl.addUserRoles(userId, roles, (err) => {
					if (err) { 
						reject(err); 
					} else {
						resolve();
					}
				});
			});
		})
		.then(() => redisClient.quit())
		.catch(err => {
			redisClient.quit();
			throw err;
		});
}

function retrieveUserSubResourceRoles(userId, resources) {
	const resourceTypes = {
		"Account": {
			model: userAccountRole,
			key: 'account_id'
		},
		"Location": {
			model: userLocationRole,
			key: 'location_id'
		},
		"AccountGroup": {
			model: userAccountGroupRole,
			key: 'group_id'
		}
	};
	
	return Promise.all(
		resources
			.filter(resource => resourceTypes[resource])
			.map(resource => {
				const resourceType = resourceTypes[resource];
		
				return resourceType.model.retrieveByUserId({ user_id: userId })
					.then(({ Items }) => {
						if (!Items.length) {
							return new Promise((resolve, reject) => reject(new Error('Unable to retrieve user subresource roles')));
						}

						return Items
							.map(item => item.roles.map(role => createSubResourceRole(resource, item[resourceType.key], role)))
							.reduce((acc, roles) => acc.concat(roles), []);
					});
			})
	)
	.then(subResourceRoles => {
		return subResourceRoles.reduce((acc, roles) => acc.concat(roles), []);
	});
}

function parseRoles(subResource, roles) {
	return roles.map(role => {
		if (role.startsWith(subResource)) {
			let splitRole = role.split('.');
			return splitRole
				.map((elm, i) => i === 0 || i === splitRole.length - 1 ? elm : '*')
				.join('.');
		} else {
			return role;
		}
	});
}


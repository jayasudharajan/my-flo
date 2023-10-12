import Acl from 'acl';
import { getClient } from './cache';

var acl = null;

export function getAcl() {

	if (!acl) {
		acl = new Acl(new Acl.redisBackend(getClient()));
	}

	return acl;
}

export function addUserRoles(userId, roles) {
	return new Promise((resolve, reject) => {
		getAcl().addUserRoles(userId, roles, (err) => {
			if (err) {
				reject(err);
			} else {
				resolve();
			}
		});
	});
}

export function removeUserRoles(userId, roles) {
	return new Promise((resolve, reject) => {
		getAcl().removeUserRoles(userId, roles, (err) => {
			if (err) {
				reject(err);
			} else {
				resolve();
			}
		});
	});
}

export function userRoles(userId) {
	return new Promise((resolve, reject) => {
		getAcl().userRoles(userId, (err, roles) => {
			if (err) {
				reject(err);
			} else {
				resolve(roles);
			}
		});
	});
}

export function hasRole(userId, role) {
	return new Promise((resolve, reject) => {
		getAcl().hasRole(userId, role, (err, result) => {
			if (err) {
				reject(err);
			} else {
				resolve(result);
			}
		});
	});
}

export function isAllowed(userId, resource, permission) {
	return new Promise((resolve, reject) => {
		getAcl().isAllowed(userId, resource, permission, (err, allowed) => {
			if (err) {
				reject(err);
			} else {
				resolve(allowed);
			}
		});
	});
}

export function areAnyRolesAllowed(roles, resource, permissions) {
	return new Promise((resolve, reject) => {
		getAcl().areAnyRolesAllowed(roles, resource, permissions, (err, allowed) => {
			if (err) {
				reject(err);
			} else {
				resolve(allowed);
			}
		});
	});
}

export function replaceUserRoles(userId, newRoles) {
	let roles = Array.isArray(newRoles) ? newRoles : [newRoles];
	let redisClient = getClient();
	let transaction = redisClient.multi();
	let backend = new Acl.redisBackend(redisClient);
	let _end = backend.end;
	let isReadyToExec = false;
	let deferred = Promise.defer();

	backend.begin = () => transaction;
	backend.end = (trans, cb) => isReadyToExec ? _end(trans, cb) : cb();
	
	let _acl = new Acl(backend);

	userRoles(userId)
		.then(oldRoles => {
			const obsoleteRoles = (oldRoles || []).filter(role => roles.indexOf(role) < 0);
			
			_acl.removeUserRoles(userId, obsoleteRoles, () => {
				
				isReadyToExec = true;

				_acl.addUserRoles(userId, roles, err => {
					if (err) {
						deferred.reject(err);
					} else {
						deferred.resolve();
					}
				})
			
			});
		})
		.catch(err => deferred.reject(err));

	return deferred.promise;
}

export function removeAllUserRoles(userId) {
	return userRoles(userId)
		.then(roles => {
			return removeUserRoles(userId, roles);
		});
}

export function createSubResourceRole(resourceName, resourceId, role) {
	return `${ resourceName }.${ resourceId }.${ role }`;
}

export function isSubResourceRole(resourceName, resourceId, role) {
	return role.startsWith(resourceName + '.' + resourceId + '.');
}

export function parseSubResourceRole(subResourceeRole) {
	let [ resourceType, resourceId, role ] = subResourceeRole.split('.');

 	return { resourceType, resourceId, role };
}

export function formatUserId(userId, clientId, nonce) {
	const userIdNonce = (userId || '') + (nonce ? `_${ nonce }` : '');

	if (!clientId) {
		return userIdNonce;
	} else if (!userId || userIdNonce === clientId) {
		return `client@${ clientId }`;
	} else {
		return `${ userIdNonce }:${ clientId }`;
	}
}

class ACLServiceMock {

	constructor() {
		this.acl = {};
	}

	createSubResourceRole(resourceName, resourceId, role) {
		return `${ resourceName }.${ resourceId }.${ role }`;
	}

	replaceUserRoles(userId) {
		return Promise.resolve();
	}

	formatUserId(userId, clientId) {
		if (!clientId) {
			return userId;
		} else if (userId === clientId) {
			return `client@${ clientId }`;
		} else {
			return `${ userId }:${ clientId }`;
		}
	}

	allow(userId, resource, permission) {
		if (!this.acl[userId] || !this.acl[userId][resource]) {
			this.acl[userId] = Object.assign(
				this.acl[userId] || {},
				{ [resource]: [permission] }
			);
		} else {
			this.acl[userId][resource].push(permission);
		}
	}

	isAllowed(userId, resource, permission) {

		return Promise.resolve(
			((this.acl[userId] || {})[resource] || []).indexOf(permission) >= 0
		);
	}
}

module.exports = ACLServiceMock;
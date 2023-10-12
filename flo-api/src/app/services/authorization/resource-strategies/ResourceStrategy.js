import _ from 'lodash';

class ResourceStrategy {
	constructor(resourceName, subResourceId, subResourceTable) {
		this.resourceName = resourceName;
		this.subResourceId = subResourceId;
		this.subResourceTable = subResourceTable;
	}

	getSubResourceRolesByUserId(userId) {
		return this.subResourceTable.retrieveByUserId(userId)
			.then(({ Items }) =>
				_.flatMap(Items, (item => 
					item.roles.map(role => this.createResourceRole(item[this.subResourceId], role))
				))
			);
	}

	assignRoles(userId, subResourceId, roles, metadata = {}) {
		return this.subResourceTable.create({
			user_id: userId,
			[this.subResourceId]: subResourceId,
			roles,
			...metadata
		});
	}

	removeRoles(userId, subResourceId) {
		return this.subResourceTable.remove({
			user_id: userId,
			[this.subResourceId]: subResourceId
		});
	}

	retrieveSubResources(userId) {
		return this.subResourceTable.retrieveByUserId(userId)
			.then(({ Items }) => Items.map(item => item[this.subResourceId]));
	}

	createResourceRole(subResourceId, role) {
		return `${ this.resourceName }.${ subResourceId }.${ role }`;
	}

	parseRole(role) {
		if (role.startsWith(this.resourceName)) {
			const splitRole = role.split('.');

			return splitRole.length >= 3 && splitRole
				.map((elm, i) => i === 0 || i === splitRole.length - 1 ? elm : '*')
				.join('.');
		}
	}
}

export default ResourceStrategy;
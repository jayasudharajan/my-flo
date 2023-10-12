import _ from 'lodash';
import ACLService from '../utils/ACLService';
import ResourceStrategyFactory from './resource-strategies/ResourceStrategyFactory';
import UserAccountRoleTable from './UserAccountRoleTable';
import UserLocationRoleTable from './UserLocationRoleTable';
import UserAccountGroupRoleTable from './UserAccountGroupRoleTable';
import SystemUserService from '../system-user/SystemUserService';
import DIFactory from  '../../../util/DIFactory';

class AuthorizationService {
	constructor(aclService, resourceStrategyFactory, systemUserService) {
		this.aclService = aclService;
		this.resourceStrategyFactory = resourceStrategyFactory;
		this.systemUserService = systemUserService;
	}

	assignUserResourceRoles(userId, resourceName, subResourceId, roles, metadata) {
		return this.resourceStrategyFactory.getResourceStrategy(resourceName)
			.assignRoles(userId, subResourceId, roles, metadata);
	}

	removeUserResourceRoles(userId, resourceName, subResourceId) {
		return this.resourceStrategyFactory.getResourceStrategy(resourceName)
			.removeRoles(userId, subResourceId);
	}

	retrieveUserResources(userId, resourceName) {
		return this.resourceStrategyFactory.getResourceStrategy(resourceName)
			.retrieveSubResources(userId);
	}

	createResourceRoles(userId, resourceName, role) {
		return this.retrieveUserResources(userId, resourceName)
			.then(subResourceIds =>
				subResourceIds.map(subResourceId =>
					this.resourceStrategyFactory
						.getResourceStrategy(resourceName)
						.createResourceRole(subResourceId, role)
				)
			);
	}

	retrieveSystemUserRoles(userId) {
		return this.systemUserService.retrieveDetail(userId)
			.then(detail => (detail || {}).roles || []);
	}

	retrieveUserRoles(userId) {

		return Promise.all([
			this.resourceStrategyFactory.getSubResourceRolesByUserId(userId),
			this.retrieveSystemUserRoles(userId)
		])
		.then(([ subResourceRoles, systemUserRoles ]) =>			
			[
				'user',
			]
			.concat(subResourceRoles)
			.concat(systemUserRoles)
		);
	}

	retrieveUserAccountGroupRolesByGroupId(groupId) {
		return this.resourceStrategyFactory.getResourceStrategy('AccountGroup')
			.retrieveUserRolesByGroupId(groupId);
	}

	retrieveUserAccountGroupRolesByUserId(userId) {
		return this.resourceStrategyFactory.getResourceStrategy('AccountGroup')
			.retrieveUserRolesByUserId(userId);
	}

	updateUserACLRoles(userId, roles, clientId, nonce) {
		return this.aclService.replaceUserRoles(this.aclService.formatUserId(userId, clientId, nonce), roles);
	}

	loadUserACLRoles(userId, clientId) {

		return this.retrieveUserRoles(userId)
			.then(roles => this.updateUserACLRoles(userId, roles, clientId));
	}

	isAllowed(resource, permission, userId, clientId, nonce) {
		const formatedUserId = this.aclService.formatUserId(userId, clientId, nonce);

		return this.aclService.isAllowed(formatedUserId, resource, permission)
			.then(isAllowed => 
				isAllowed || 
				this.aclService.userRoles(formatedUserId)
					.then(roles => this.aclService.areAnyRolesAllowed(this.parseRoles(roles), resource, permission))
			);
	}

	validateRoles(resource, permission, userId, clientId, nonce, getSubResource) {
		const formatedUserId = this.aclService.formatUserId(userId, clientId, nonce);

		return getSubResource ?
			this.aclService.userRoles(formatedUserId)
				.then(userRoles => this.processSubResourceRoles(userRoles, getSubResource))
				.then(processedRoles => this.aclService.areAnyRolesAllowed(processedRoles, resource, permission)) :
			this.aclService.isAllowed(formatedUserId, resource, permission);
	}

	processSubResourceRoles(userRoles, getSubResource) {
		return getSubResource()
			.then(result => {
				return _.flatMap(
					_.isArray(result) ? result : [result],
					subResource => {
						return userRoles
							.map(role => {
								if (subResource && role.startsWith(subResource)) {
									const splitRole = role.split('.');
									return `${ splitRole[0] }.*.${ splitRole[splitRole.length - 1] }`
								} else {
									return role;
								}
							});
					})
			});
	}

	parseRoles(roles) {
		return roles.map(role => this.resourceStrategyFactory.parseRole(role));
	}

	retrieveRoles(userId, clientId, nonce) {
		const formatedUserId = this.aclService.formatUserId(userId, clientId, nonce);

		return this.aclService.userRoles(formatedUserId);
	}
}

export default new DIFactory(AuthorizationService, [ACLService, ResourceStrategyFactory, SystemUserService]);

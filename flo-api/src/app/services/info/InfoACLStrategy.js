export default class InfoACLStrategy {
	constructor(aclMiddleware) {
		this.retrieveAllUsers = aclMiddleware.requiresPermissions([{
			resource: 'User',
			permission: 'retrieveAll'
		}]);

		this.retrieveUserByUserId = aclMiddleware.requiresPermissions([
			{
				resource: 'User',
				permission: 'retrieve'
			},
			{
				resource: 'User',
				permission: 'retrieveUserInfo',
				get: req => Promise.resolve(req.params.user_id)
			}
		]);

		this.retrieveAllICDs = aclMiddleware.requiresPermissions([{
			resource: 'ICD',
			permission: 'retrieveAll'
		}]);

		this.retrieveICDByICDId = aclMiddleware.requiresPermissions([{
			resource: 'ICD',
			permission: 'retrieve'
		}]);

		this.retrieveAllGroupUsers = aclMiddleware.requiresPermissions([
			{
				resource: 'User',
				permission: 'retrieveAll'
			},
			{
				resource: 'AccountGroup',
				permission: 'retrieveAllGroupUsers',
				get: req => Promise.resolve(req.params.group_id)
			}
		]);

		this.retrieveAllGroupICDs = aclMiddleware.requiresPermissions([
			{
				resource: 'User',
				permission: 'retrieveAll'
			},
			{
				resource: 'AccountGroup',
				permission: 'retrieveAllGroupICDs',
				get: req => Promise.resolve(req.params.group_id)
			}
		]);

		this.retrieveGroupUserByUserId = aclMiddleware.requiresPermissions([
			{
				resource: 'User',
				permission: 'retrieve'
			},
			{
				resource: 'AccountGroup',
				permission: 'retrieveUser',
				get: req => Promise.resolve(req.params.group_id)
			}
		]);

		this.retrieveGroupICDByICDId = aclMiddleware.requiresPermissions([
			{
				resource: 'User',
				permission: 'retrieve'
			},
			{
				resource: 'AccountGroup',
				permission: 'retrieveICD',
				get: req => Promise.resolve(req.params.group_id)
			}
		]);

		this.aggregateICDsByOnboardingEvent = aclMiddleware.requiresPermissions([{
			resource: 'ICD',
			permission: 'retrieveAll'
		}]);

		this.retrieveDevicesLeakStatus = aclMiddleware.requiresPermissions([{
			resource: 'ICD',
			permission: 'retrieveAll'
		}]);

		this.retrieveLeakStatusCounts = aclMiddleware.requiresPermissions([{
			resource: 'ICD',
			permission: 'retrieveAll'
		}]);

		this.retrieveAllICDsWithScroll = aclMiddleware.requiresPermissions([{
			resource: 'ICD',
			permission: 'scrollAll'
		}]);

		this.scrollAllICDs = aclMiddleware.requiresPermissions([{
			resource: 'ICD',
			permission: 'scrollAll'
		}]);
	}
}
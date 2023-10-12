export default class UserAccountACLStrategy {
	constructor(aclMiddleware) {
		this.createNewUserAndAccount = aclMiddleware.requiresPermissions([{
			resource: 'UserAccount',
			permission: 'createNewUserAndAccount'
		}]);

    this.removeUserAndAccount = aclMiddleware.requiresPermissions([
      {
        resource: 'UserAccount',
        permission: 'removeUserAndAccount'
      }
    ]);
	}
}
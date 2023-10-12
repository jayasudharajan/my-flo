import ResourceStrategy from './ResourceStrategy';

class UserResourceStrategy extends ResourceStrategy {
	constructor() {
		super('User', 'user_id', { 
			retrieveByUserId(userId) {
				return Promise.resolve({
					Items: [{ user_id: userId, roles: ['self'] }]
				});
			}
		});
	}
}

export default UserResourceStrategy;
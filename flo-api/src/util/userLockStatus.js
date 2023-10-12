import UserLockStatusTable from '../app/models/UserLockStatusTable';

const UserLockStatus = new UserLockStatusTable();

export const LOCK_STATUS = {
	LOCKED: 'locked',
	UNLOCKED: 'unlocked'
}

export function getLockStatus(user_id) {
	return UserLockStatus.retrieveLatest({ user_id })
		.then(({ Items }) => {
			if (Items && Items.length) {
				return Items[0].status;
			} else {
				return LOCK_STATUS.UNLOCKED;
			}
		});
}

export function setLockStatus(user_id, status) {
	return UserLockStatus.createLatest({ user_id, status });
}


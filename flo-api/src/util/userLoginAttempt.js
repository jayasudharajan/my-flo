import _ from 'lodash';
import moment from 'moment';
import UserLoginAttemptTable from '../app/models/UserLoginAttemptTable';
import config from '../config/config';

const UserLoginAttempt = new UserLoginAttemptTable();

export const LOGIN_ATTEMPT_STATUS = {
	SUCCESS: 'success',
	FAIL: 'fail',
	RESET: 'reset'
}

export function logAttempt(user_id, isSuccess) {
	return UserLoginAttempt.createLatest({ 
		user_id, 
		status: isSuccess ? LOGIN_ATTEMPT_STATUS.SUCCESS : LOGIN_ATTEMPT_STATUS.FAIL 
	});
}

export function countFailedAttempts(user_id) {
	const minutesAgo = moment().subtract(config.failedLoginAttemptsMinutes, 'minutes').toISOString();

	return UserLoginAttempt.retrieveAfter({ user_id }, { start: minutesAgo, limit: config.maxFailedLoginAttempts, descending: true })
		.then(({ Items }) => 
			_.takeWhile(Items || [], ({ status }) => status === LOGIN_ATTEMPT_STATUS.FAIL).length
		);
}

export function resetCount(user_id) {
	return UserLoginAttempt.createLatest({
		user_id,
		status: LOGIN_ATTEMPT_STATUS.RESET
	});
}
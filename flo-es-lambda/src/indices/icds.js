const esClient = require('../db/esClient');
const esUtil = require('../util/esUtil');
const dynamoClient = require('../db/dynamoClient');
const util = require('../util/util');
const doctypes = require('../util/doctypes');
const EVENTS = util.EVENTS;

const updateICD = (id, body, attempts = 2) => {

	return esClient.update({
		index: 'icds',
		type: 'icd',
		id,
		retryOnConflict: 10,
		body
	})
	.catch(err => {
		if (err.status == 404 && attempts > 0) {
			const deferred = Promise.defer();

			setTimeout(() => {
				updateICD(id, body, attempts - 1)
					.then(result => deferred.resolve(result))
					.catch(err => deferred.reject(err));
			}, (3 - attempts) * 250);

			return deferred.promise

		} else if (err.status == 404) {
			console.log('[WARNING] icds icd ' + id + ' not found.');
			return Promise.resolve();
		} else {
			return Promise.reject(err);
		}
	});
}

const removeICD = id => new Promise((resolve, reject) => 
	esClient.delete({ index: 'icds', type: 'icd', id })
		.then(res => resolve(res))
		.catch(err => {
			if (err.status == 404) {
				resolve();
			} else {
				reject(err);
			}
		})
);

module.exports = pubsub => {

	pubsub.subscribe('ICD', [EVENTS.INSERT, EVENTS.MODIFY], icd => {

		return joinICDToLocation(icd.location_id)
			.then(location => 
				Promise.all([
						location && retrieveAccount(location.account_id),
						location && joinLocationToUsers(location.location_id)
							.then(user_ids => 
								Promise.all(user_ids.map(user_id => retrieveUser(user_id)))
							),
						location && retrieveAccountSubscription(location.account_id)
				])
				.then(result => {
					const account = result[0];
					const users = result[1];
					const subscription = result[2];
					const doc = doctypes.createICD({ icd, location, account, users, subscription });

					return updateICD(icd.id, { doc, upsert: doc });
				})
			);
	});


	pubsub.subscribe('ICD', [EVENTS.REMOVE], icd => {
		return removeICD(icd.id);
	});

	pubsub.subscribe('Location', [EVENTS.INSERT, EVENTS.MODIFY], location => {
		return joinLocation(location.location_id)
			.then(icd_ids => Promise.all(
				icd_ids.map(icd_id => {
					const doc = doctypes.createICD({ location });

					return updateICD(icd_id, { doc, upsert: doc });
				})
			));
	});

	pubsub.subscribe('Account', [EVENTS.INSERT, EVENTS.MODIFY], account => {
		return joinAccount(account.id)
			.then(icd_ids => Promise.all(
				icd_ids.map(icd_id => {
					const doc = doctypes.createICD({ account });

					return updateICD(icd_id, { doc, upsert: doc });
				})
			));
	});

	pubsub.subscribe('User', [EVENTS.INSERT, EVENTS.MODIFY], user => {
		return joinUser(user.id)
			.then(icd_ids => Promise.all(
				icd_ids.map(icd_id => {
					const userData = { user_id: user.id, email: user.email };
					const script = esUtil.mergeArrayItem('users', userData, 'user_id');
					const body = {
						script,
						upsert: {
							id: icd_id,
							users: [userData]
						}
					};

					return updateICD(icd_id, body);
				})
			));
	});

	pubsub.subscribe('User', [EVENTS.REMOVE], user => {
		return joinUser(user.id)
			.then(icd_ids => Promise.all(
				icd_ids.map(icd_id => {
					const script = esUtil.removeArrayItem('users', { user_id: user.id }, 'user_id');
					const body = {
						script
					};

					return updateICD(icd_id, body);
				})
			));
	});

	pubsub.subscribe('UserDetail', [EVENTS.INSERT, EVENTS.MODIFY], userDetail => {
		return joinUser(userDetail.user_id)
			.then(icd_ids => Promise.all(
				icd_ids.map(icd_id => {
					const userData = { 
						user_id: userDetail.user_id, 
						firstname: userDetail.firstname, 
						lastname: userDetail.lastname 
					};
					const script = esUtil.mergeArrayItem('users', userData, 'user_id');
					const body = {
						script,
						upsert: {
							id: icd_id,
							users: [userData]
						}
					};

					return updateICD(icd_id, body);
				})
			));
	});

	pubsub.subscribe('UserDetail', [EVENTS.REMOVE], userDetail => {
		return joinUser(userDetail.user_id)
			.then(icd_ids => Promise.all(
				icd_ids.map(icd_id => {
					const script = esUtil.removeArrayItem('users', { user_id: userDetail.user_id }, 'user_id');
					const body = {
						script
					};

					return updateICD(icd_id, body);
				})
			))
			.catch(err => {
				if (err.status == 404) {
					return Promise.resolve();
				}

				return Promise.reject(err);
			});
	});

	pubsub.subscribe('OnboardingLog', [EVENTS.INSERT, EVENTS.MODIFY], onboardingLog => {

		if (!Date.parse(onboardingLog.created_at)) {
			return Promise.resolve();
		}

		const icdId = onboardingLog.icd_id;
		const onboardingData = { created_at: onboardingLog.created_at, event: onboardingLog.event };
		const script = esUtil.insertArrayItem('onboarding', onboardingData);
		const body = {
			script,
			upsert: {
				id: icdId,
				onboarding: [onboardingData]
			}
		};

		return updateICD(icdId, body);
	});

	pubsub.subscribe('UserLocationRole', [EVENTS.INSERT], userLocationRole => {
		return Promise.all([
			retrieveUser(userLocationRole.user_id),
			joinLocation(userLocationRole.location_id)
		])
		.then(result => {
			const userData = {
				user_id: result[0].user_id,
				email: result[0].email,
				firstname: result[0].firstname,
				lastname: result[0].lastname
			};
			const icdIds = result[1];
			const script = esUtil.mergeArrayItem('users', userData, 'user_id');

			return Promise.all(
				icdIds.map(icdId => updateICD(icdId, {
					script,
					upsert: {
						id: icdId,
						users: [userData]
					}
				}))
			);
		});
	});

	pubsub.subscribe('AlarmNotificationDeliveryFilter', [EVENTS.INSERT, EVENTS.MODIFY], alarmNotificationDeliveryFilter => {

		if (!alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id) {
			return Promise.resolve();
		}

		const icdId = alarmNotificationDeliveryFilter.icd_id;
		const alertData = util.omit(alarmNotificationDeliveryFilter, ['icd_id', 'last_decision_user_id']);
		const script = alertData.status == 3 ? 
			esUtil.replaceArrayItem('pending_alerts', alertData, 'last_icd_alarm_incident_registry_id') :
			esUtil.removeArrayItem('pending_alerts', alertData, 'alarm_id_system_mode');
		const body = Object.assign(
			{
				script
			},
			alertData.status == 3 ? 
				{ upsert: { id: icdId, pending_alerts: [alertData] } } : 
				{}
		);

		return updateICD(icdId, body);
	});

	pubsub.subscribe('AlarmNotificationDeliveryFilter', [EVENTS.REMOVE], alarmNotificationDeliveryFilter => {
		const icdId = alarmNotificationDeliveryFilter.icd_id;
		const alertData = util.pick(alarmNotificationDeliveryFilter, ['alarm_id_system_mode']);
		const script = esUtil.removeArrayItem('pending_alerts', alertData, 'alarm_id_system_mode');
		const body = { script };

		return updateICD(icdId, body);
	});

	pubsub.subscribe('AccountSubscription', [EVENTS.INSERT, EVENTS.MODIFY], accountSubscription => {
		const account_id = accountSubscription.account_id;
		const subscriptionData = util.omit(accountSubscription, ['account_id']);
		const doc = {
			account: {
				account_id,
				subscription: subscriptionData
			}
		};

		return joinAccount(account_id)
			.then(icdIds => Promise.all(
				icdIds.map(icdId => updateICD(icdId, { 
					doc, 
					upsert: Object.assign(
						{	id: icdId	},
						doc
					) 
				}))
			));
	});

	pubsub.subscribe('AccountSubscription', [EVENTS.REMOVE], accountSubscription => {
		const account_id = accountSubscription.account_id;

		return esClient.updateByQuery({
			index: 'icds',
			type: 'icd',
			body: {
				query: {
					bool: {
						filter: {
							term: {
								'account.account_id': account_id
							}
						}
					}
				},
				script: {
					inline: 'if (ctx._source.containsKey("account")) { ctx._source.account.remove("subscription"); } ',
					lang: 'painless'
				}
			}
		});
	});
};

function joinICDToLocation(location_id) {
	return dynamoClient.query({
		TableName: util.getTableName('Location'),
		IndexName: 'LocationIdIndex',
		KeyConditionExpression: '#location_id = :location_id',
		ExpressionAttributeNames: {
			'#location_id': 'location_id'
		},
		ExpressionAttributeValues: {
			':location_id': location_id
		}
	})
	.promise()
	.then(result => result.Items[0]);
}

function retrieveAccount(account_id) {
	return dynamoClient.get({
		TableName: util.getTableName('Account'),
		Key: {
			id: account_id
		}
	})
	.promise()
	.then(result => result.Item);
}

function joinLocation(location_id) {
	return dynamoClient.query({
		TableName: util.getTableName('ICD'),
		IndexName: 'LocationIdIndex',
		KeyConditionExpression: '#location_id = :location_id',
		ExpressionAttributeNames: {
			'#location_id': 'location_id'
		},
		ExpressionAttributeValues: {
			':location_id': location_id
		}
	})
	.promise()
	.then(result => result.Items.map(item => item.id));
}

function joinAccount(account_id) {
	return dynamoClient.query({
		TableName: util.getTableName('Location'),
		KeyConditionExpression: '#account_id = :account_id',
		ExpressionAttributeNames: {
			'#account_id': 'account_id'
		},
		ExpressionAttributeValues: {
			':account_id': account_id
		}
	})
	.promise()
	.then(result => Promise.all(
		result.Items.map(item => joinLocation(item.location_id))
	))
	.then(results => 
		results.reduce((acc, icd_ids) => acc.concat(icd_ids), [])
	);
}

function joinUser(user_id) {
	return dynamoClient.query({
		TableName: util.getTableName('UserLocationRole'),
		KeyConditionExpression: '#user_id = :user_id',
		ExpressionAttributeNames: {
			'#user_id': 'user_id'
		},
		ExpressionAttributeValues: {
			':user_id': user_id
		}
	})
	.promise()
	.then(result =>
		Promise.all( 
			(result.Items || []).map(userLocationRole => 
				dynamoClient.query({
					TableName: util.getTableName('ICD'),
					IndexName: 'LocationIdIndex',
					KeyConditionExpression: '#location_id = :location_id',
					ExpressionAttributeNames: {
						'#location_id': 'location_id'
					},
					ExpressionAttributeValues: {
						':location_id': userLocationRole.location_id
					}
				})
				.promise()
			)
		)
	)
	.then(results => 
			results
				.reduce((acc, result) => acc.concat(result.Items || []), [])
				.map(icd => icd.id)
	);
}

function joinLocationToUsers(location_id) {
	return dynamoClient.query({
		TableName: util.getTableName('UserLocationRole'),
		IndexName: 'LocationIdIndex',
		KeyConditionExpression: '#location_id = :location_id',
		ExpressionAttributeNames: {
			'#location_id': 'location_id'
		},
		ExpressionAttributeValues: {
			':location_id': location_id
		}
	})
	.promise()
	.then(result => (result.Items || []).map(userLocationRole => userLocationRole.user_id));
}

function retrieveUser(user_id) {
	return Promise.all([
		dynamoClient.get({
			TableName: util.getTableName('User'),
			Key: {
				id: user_id
			}
		})
		.promise()
		.then(result => result.Item || {}),
		dynamoClient.get({
			TableName: util.getTableName('UserDetail'),
			Key: {
				user_id
			}
		})
		.promise()
		.then(result => result.Item || {})
	])
	.then(result => ({
		user_id: result[0].id || result[1].user_id,
		firstname: result[1].firstname,
		lastname: result[1].lastname,
		email: result[0].email
	}));
}

function retrieveAccountSubscription(account_id) {
	return dynamoClient.get({
		TableName: util.getTableName('AccountSubscription'),
		Key: {
			account_id: account_id
		}
	})
	.promise()
	.then(result => result.Item || {});
}
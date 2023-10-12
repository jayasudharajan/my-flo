const esClient = require('../db/esClient');
const esUtil = require('../util/esUtil');
const dynamoClient = require('../db/dynamoClient');
const util = require('../util/util');
const EVENTS = util.EVENTS;

const indexUser = (id, body) => esClient.index({ index: 'users', type: 'user', id, body });
const updateUser = (id, body) => esClient.update({ index: 'users', type: 'user', id, body, retryOnConflict: 2 });
const removeUser = id => new Promise((resolve, reject) => 
	esClient.delete({ index: 'users', type: 'user', id })
		.then(resolve)
		.catch(err => err.status === 404 ? resolve() : reject(err))
);

module.exports = pubsub => {
	pubsub.subscribe('User', [EVENTS.INSERT, EVENTS.MODIFY], user => {
		const doc = Object.assign({
			id: user.id,
			email: user.email,
			is_active: user.is_active,
			is_system_user: !!user.is_system_user
		}, !user.source ? {} : {
			source: user.source
		});
		
		return updateUser(user.id, {
			doc,
			upsert: doc
		});
	});

	pubsub.subscribe('User', [EVENTS.REMOVE], user => {
		return removeUser(user.id);
	});

	pubsub.subscribe('UserDetail', [EVENTS.INSERT, EVENTS.MODIFY], userDetail => {
		const doc = {
			firstname: userDetail.firstname,
			lastname: userDetail.lastname,
			middlename: userDetail.middlename,
			phone_mobile: userDetail.phone_mobile
		};

		return updateUser(userDetail.user_id, {
			doc,
			upsert: doc
		});
	});

	pubsub.subscribe('Location', [EVENTS.INSERT, EVENTS.MODIFY], location => {
		const geo_location = util.createGeoLocation(location);
		const script = esUtil.replaceArrayItem('geo_locations', geo_location, 'location_id');

		return joinLocation(location.location_id)
			.then(user_ids => {
				const promises = user_ids
					.map(user_id => {
						const body = {
							script,
							upsert: {
								id: user_id,
								geo_locations: [geo_location]
							}
						};

						return updateUser(user_id, body);
					});

				return Promise.all(promises);
			});
	});

	pubsub.subscribe('Location', [EVENTS.REMOVE], location => {
		const geo_location = util.createGeoLocation(location);
		const script = esUtil.removeArrayItem('geo_locations', geo_location, 'location_id');

		return joinLocation(location.location_id)
			.then(user_ids => {
				const promises = user_ids
					.map(user_id => {
						const body = {
							script
						};

						return updateUser(user_id, body)
							.catch(err => {
								if (err.status == 404) {
									return Promise.resolve();
								}

								return Promise.reject(err);
							});
					});

				return Promise.all(promises);
			});
	});

	pubsub.subscribe('Account', [EVENTS.INSERT, EVENTS.MODIFY], account => {
		return joinAccount(account.id)
			.then(user_ids => {
				const promises = user_ids
					.map(user_id => {
						const doc = { 
							account: util.createAccount(account)
						};
						return updateUser(user_id, { doc, upsert: doc });
					});

				return Promise.all(promises);
			});
	});

	pubsub.subscribe('ICD', [EVENTS.INSERT, EVENTS.MODIFY], icd => {
		const script = esUtil.replaceArrayItem('devices', icd, 'id');

		return joinLocation(icd.location_id)
			.then(user_ids => {
				const promises = user_ids
					.map(user_id => {
						const body = { 
							script,
							upsert: {
								id: user_id,
								devices: [icd]
							} 
						};

						return updateUser(user_id, body);
					});

				return Promise.all(promises);
			});
	});

	pubsub.subscribe('ICD', [EVENTS.REMOVE], icd => {
		const script = esUtil.removeArrayItem('devices', icd, 'id');

		return joinLocation(icd.location_id)
			.then(user_ids => {
				const promises = user_ids
					.map(user_id => {
						const body = { script };

						return updateUser(user_id, body)
							.catch(err => {
								if (err.status == 404) {
									return Promise.resolve();
								}

								return Promise.reject(err);
							});
					});

				return Promise.all(promises);
			});
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
			.then(userIds => Promise.all(
				userIds.map(userId => updateUser(userId, { 
					doc, 
					upsert: Object.assign(
						{	id: userId },
						doc
					)
				}))
			));
	});

	pubsub.subscribe('AccountSubscription', [EVENTS.REMOVE], accountSubscription => {
		const account_id = accountSubscription.account_id;

		return esClient.updateByQuery({
			index: 'users',
			type: 'user',
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

function joinLocation(location_id) {
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
	.then(result => result.Items.map(userLocationRole => userLocationRole.user_id));
}

function joinAccount(account_id) {
	return dynamoClient.query({
		TableName: util.getTableName('UserAccountRole'),
		IndexName: 'AccountIdIndex',
		KeyConditionExpression: '#account_id = :account_id',
		ExpressionAttributeNames: {
			'#account_id': 'account_id'
		},
		ExpressionAttributeValues: {
			':account_id': account_id
		}
	})
	.promise()
	.then(result => result.Items.map(userAccountRole => userAccountRole.user_id));
}

function retrieveLocation(location_id) {
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
	.then(({ Items }) => Items[0]);
}

function retrieveAccount(account_id) {
	return dynamoClient.query({
		TableName: util.getTableName('Account'),
		KeyConditionExpression: '#account_id = :account_id',
		ExpressionAttributeNames: {
			'#account_id': 'id'
		},
		ExpressionAttributeValues: {
			':account_id': account_id
		}
	})
	.promise()
	.then(({ Items }) => Items[0]);
}

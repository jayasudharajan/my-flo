const esClient = require('../db/esClient');
const esUtil = require('../util/esUtil');
const dynamoClient = require('../db/dynamoClient');
const util = require('../util/util');
const doctypes = require('../util/doctypes');
const EVENTS = util.EVENTS;

function indexICDAlarmIncidentRegistry(id, body, timestamp) {

	if (new Date(timestamp) < new Date('2018-01-01T00:00:00.000Z')) {
    return Promise.resolve();
  }

	return esClient.index({ 
		index: util.getLogIndexName('icdalarmincidentregistries', timestamp),
		type: 'icdalarmincidentregistry', 
		id, 
		body 
	});
}

function updateICDAlarmIndicentRegistry(id, body, timestamp) {

	if (new Date(timestamp) < new Date('2018-01-01T00:00:00.000Z')) {
    return Promise.resolve();
  }

 return esClient.update({
		index: util.getLogIndexName('icdalarmincidentregistries', timestamp),
		type: 'icdalarmincidentregistry',
		retryOnConflict: 2,
		id,
		body
	});
}

module.exports = pubsub => {

	pubsub.subscribe('ICDAlarmIncidentRegistry', [EVENTS.INSERT, EVENTS.MODIFY], icdAlarmIncidentRegistry => {

		if (
			!Date.parse(icdAlarmIncidentRegistry.incident_time) ||
			icdAlarmIncidentRegistry.incident_time > new Date().toISOString() || 
			!icdAlarmIncidentRegistry.account_id ||
			!icdAlarmIncidentRegistry.location_id ||
			!icdAlarmIncidentRegistry.icd_id
		) {
			console.log(JSON.stringify(icdAlarmIncidentRegistry, null, 4));
			return Promise.resolve();
		}

		return Promise.all([
			joinAccount(icdAlarmIncidentRegistry.account_id),
			joinLocation(icdAlarmIncidentRegistry.location_id, icdAlarmIncidentRegistry.account_id),
			joinOnboardingLog(icdAlarmIncidentRegistry.icd_id)
		])
		.then(results => {
			const account = results[0];
			const location = results[1];
			const onboardingLog = results[2];
			const doc = doctypes.createICDAlarmIncidentRegistry(
				icdAlarmIncidentRegistry,
				account, 
				location,
				onboardingLog
			);

			return indexICDAlarmIncidentRegistry(doc.id, doc, doc.created_at);
		});
	});
};

function joinAccount(account_id) {
	return dynamoClient.get({
		TableName: util.getTableName('Account'),
		Key: { id: account_id }
	})
	.promise()
	.then(result => result.Item);
}

function joinLocation(location_id, account_id) {
	return dynamoClient.get({
		TableName: util.getTableName('Location'),
		Key: {
			account_id,
			location_id: location_id
		}
	})
	.promise()
	.then(result => result.Item);
}

function joinOnboardingLog(icd_id) {
	return dynamoClient.query({
  	TableName: util.getTableName('OnboardingLog'),
  	IndexName: 'EventIndex',
  	KeyConditionExpression: 'icd_id = :icd_id',
  	ExpressionAttributeValues: {
  		':icd_id': icd_id
  	},
	 	ScanIndexForward: false,
	 	Limit: 1
  })
  .promise()
  .then(({ Items: [onboardingLog] }) => onboardingLog && util.pick(onboardingLog, ['event', 'created_at']));
}
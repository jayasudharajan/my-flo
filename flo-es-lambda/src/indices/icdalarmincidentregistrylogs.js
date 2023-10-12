const esClient = require('../db/esClient');
const esUtil = require('../util/esUtil');
const dynamoClient = require('../db/dynamoClient');
const util = require('../util/util');
const doctypes = require('../util/doctypes')
const EVENTS = util.EVENTS;

function indexICDAlarmIncidentRegistry(id, body, timestamp) {

	if (new Date(timestamp) < new Date('2018-01-01T00:00:00.000Z')) {
    return Promise.resolve();
  }
  
	return esClient.index({ 
		index: util.getLogIndexName('icdalarmincidentregistrylogs', timestamp),
		type: 'icdalarmincidentregistrylog', 
		id, 
		body 
	});
}

module.exports = pubsub => {

	pubsub.subscribe('ICDAlarmIncidentRegistryLog', [EVENTS.INSERT], icdAlarmIncidentRegistryLog => {
		return joinICDAlarmIncidentRegistry(icdAlarmIncidentRegistryLog.icd_alarm_incident_registry_id)
			.then(icdAlarmIncidentRegistry => 
				Promise.all([
					joinLocation(
						icdAlarmIncidentRegistry.account_id, 
						icdAlarmIncidentRegistry.location_id
					),
					joinAccount(icdAlarmIncidentRegistry.account_id),
					joinOnboardingLog(icdAlarmIncidentRegistry.icd_id)
				])
			)
			.then(results => {
				const location = results[0];
				const account = results[1];
				const onboardingLog = results[2];
				const doc = doctypes.createICDAlarmIncidentRegistryLog(
					icdAlarmIncidentRegistryLog,
					account,
					location,
					onboardingLog
				);

				return indexICDAlarmIncidentRegistry(doc.id, doc, doc.created_at);
			});
	});

};

function joinICDAlarmIncidentRegistry(incident_id) {
	return dynamoClient.get({
		TableName: util.getTableName('ICDAlarmIncidentRegistry'),
		Key: {
			id: incident_id
		}
	})
	.promise()
	.then(result => result.Item);
}

function joinLocation(account_id, location_id) {
	return dynamoClient.get({
		TableName: util.getTableName('Location'),
		Key: {
			account_id,
			location_id
		}
	})
	.promise()
	.then(result => result.Item);
}

function joinAccount(account_id) {
	return dynamoClient.get({
		TableName: util.getTableName('Account'),
		Key: {
			id: account_id
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
const esClient = require('../db/esClient');
const esUtil = require('../util/esUtil');
const dynamoClient = require('../db/dynamoClient');
const util = require('../util/util');
const doctypes = require('../util/doctypes')
const EVENTS = util.EVENTS;

function indexAlarmNotificationDeliveryFilterLog(timestamp, body) {

	if (new Date(timestamp) < new Date('2018-01-01T00:00:00.000Z')) {
    return Promise.resolve();
  }

	return esClient.index({ 
		index: util.getLogIndexName('alarmnotificationdeliveryfilterlogs', timestamp), 
		type: 'alarmnotificationdeliveryfilterlog', 
		body 
	});
}

module.exports = pubsub => {

	pubsub.subscribe('AlarmNotificationDeliveryFilter', [EVENTS.INSERT, EVENTS.MODIFY], alarmNotificationDeliveryFilter => {

		if (!alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id) {
			return Promise.resolve();
		}

		return joinLocation(alarmNotificationDeliveryFilter.icd_id)
			.then(location => Promise.all([
				new Promise(resolve => resolve(location)), 
				location ? joinAccount(location.account_id) : new Promise(resolve => resolve(null)),
				joinOnboardingLog(alarmNotificationDeliveryFilter.icd_id)
			]))
			.then(locationAccountOnboardingLog => {
				const location = locationAccountOnboardingLog[0];
				const account = locationAccountOnboardingLog[1];
				const onboardingLog = locationAccountOnboardingLog[2];
				const alarmNotificationDeliveryFilterLog = doctypes.createAlarmNotificationDeliveryFilterLog(
					alarmNotificationDeliveryFilter,
					account,
					location,
					onboardingLog
				);

				return indexAlarmNotificationDeliveryFilterLog(alarmNotificationDeliveryFilter.updated_at, alarmNotificationDeliveryFilterLog);
			});
	});
};

function joinLocation(icd_id) {
	return dynamoClient.get({
		TableName: util.getTableName('ICD'),
		Key: { id: icd_id }
	})
	.promise()
	.then(result => {
		const location_id = (result.Item || {}).location_id;

		if (location_id) {
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
			.promise();
		} 
	})
	.then(result => {
		return ((result || {}).Items || [])[0];
	});
}

function joinAccount(account_id) {
	return dynamoClient.get({
		TableName: util.getTableName('Account'),
		Key: { id: account_id }
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
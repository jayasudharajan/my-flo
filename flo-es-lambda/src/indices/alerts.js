const moment = require('moment');
const esClient = require('../db/esClient');
const esUtil = require('../util/esUtil');
const dynamoClient = require('../db/dynamoClient');
const util = require('../util/util');
const doctypes = require('../util/doctypes');
const EVENTS = util.EVENTS;

function updateAlert(id, timestamp, body) {

	if (new Date(timestamp) < new Date('2018-01-01T00:00:00.000Z')) {
    return Promise.resolve();
  }

	return esClient.update({
		index: util.getLogIndexName('alerts', timestamp),
		type: 'alert',
		retryOnConflict: 2,
		id,
		body
	});
}

function clearPreviousAlerts(icd_id, alarm_id, system_mode, timestamp, clearBeforeTime, numAttempts) {

	if (new Date(timestamp) < new Date('2018-01-01T00:00:00.000Z')) {
    return Promise.resolve();
  }

	if (!numAttempts || numAttempts < 2) {
		return esClient.updateByQuery({
			index: util.generateIndexNames(
				moment(timestamp).subtract(30, 'days').toISOString(), 
				timestamp,
				'alerts'
			),
			type: 'alert',
			conflicts: 'proceed',
			body: {
				query: {
					bool: {
						filter: [
							{ term: { icd_id } },
							{ term: { alarm_id } },
							{ term: { system_mode } },
							{ term: { is_cleared: false } },
							{ range: { incident_time: { lt: clearBeforeTime } } }
						]
					}
				},
				script: {
					inline: 'ctx._source.acknowledged_by_user = 1; ctx._source.is_cleared = true;'
				}
			}
		})
		.then(result => {
			if (result.version_conflicts) {
				return clearPreviousAlerts(icd_id, alarm_id, system_mode, timestamp, clearBeforeTime, (numAttempts || 0) + 1);
			}
		});
	} else {
		return new Promise(resolve => resolve());
	}
}

module.exports = (pubsub) => {

	pubsub.subscribe('AlarmNotificationDeliveryFilter', [EVENTS.INSERT, EVENTS.MODIFY], alarmNotificationDeliveryFilter => {

		if (!alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id) {
			return Promise.resolve();
		}

		return Promise.all([
			joinLocation(alarmNotificationDeliveryFilter.icd_id),
			joinICDAlarmNotificationDeliveryRule(
				alarmNotificationDeliveryFilter.alarm_id,
				alarmNotificationDeliveryFilter.system_mode
			),
			joinICDAlarmIncidentRegistry(
				alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id
			)
		])
		.then(locationDeliveryRuleIncident => { 
			const location = locationDeliveryRuleIncident[0];
			const icdAlarmNotificationDeliveryRule = locationDeliveryRuleIncident[1];
			const icdAlarmIncidentRegistry = locationDeliveryRuleIncident[2];

			return Promise.all([
				new Promise(resolve => resolve(location)),
				new Promise(resolve => resolve(icdAlarmNotificationDeliveryRule)),
				location ? 
					joinAccount(location.account_id) : 
					new Promise(resolve => resolve(null)),
				new Promise(resolve => resolve(icdAlarmIncidentRegistry)),
				joinUserAlarmNotificationDeliveryRule(
					(location || {}).location_id, 
					alarmNotificationDeliveryFilter.alarm_id, 
					alarmNotificationDeliveryFilter.system_mode
				),
				joinOnboardingLog(alarmNotificationDeliveryFilter.icd_id)
			]);
		})
		.then(locationDeliveryRuleAccountIncidentOnboardingLog => {
			const location = locationDeliveryRuleAccountIncidentOnboardingLog[0];
			const icdAlarmNotificationDeliveryRule = locationDeliveryRuleAccountIncidentOnboardingLog[1];
			const account = locationDeliveryRuleAccountIncidentOnboardingLog[2];
			const icdAlarmIncidentRegistry = locationDeliveryRuleAccountIncidentOnboardingLog[3];
			const userAlarmNotificationDeliveryRules = locationDeliveryRuleAccountIncidentOnboardingLog[4];
			const onboardingLog = locationDeliveryRuleAccountIncidentOnboardingLog[5];

			const doc = doctypes.createAlert({ 
				alarmNotificationDeliveryFilter,
				icdAlarmNotificationDeliveryRule,
				icdAlarmIncidentRegistry,
				location, 
				account,
				userAlarmNotificationDeliveryRules,
				onboardingLog
			});			
			const id = doc.incident_id;
			const timestamp = doc.incident_time;
			
			return Promise.all(
				[updateAlert(id, timestamp, { doc, upsert: doc })].concat(
					doc.is_cleared ? 
						[clearPreviousAlerts(alarmNotificationDeliveryFilter.icd_id, alarmNotificationDeliveryFilter.alarm_id, alarmNotificationDeliveryFilter.system_mode, timestamp, alarmNotificationDeliveryFilter.updated_at)] : 
						[]
				)
			);

		});
	});

	pubsub.subscribe('ICDAlarmIncidentRegistry', [EVENTS.MODIFY], icdAlarmIncidentRegistry => {

		if (!Date.parse(icdAlarmIncidentRegistry.incident_time) || icdAlarmIncidentRegistry.incident_time > new Date().toISOString()) {
			return Promise.resolve();
		}

		const doc = doctypes.createAlert({ icdAlarmIncidentRegistry });
		const id = doc.incident_id;
		const timestamp = doc.incident_time;
		const deferred = Promise.defer();

		updateAlert(id, timestamp, { doc })
			.then(result => deferred.resolve(result))
			.catch(err => {
				if  (err.status === 404){
				 deferred.resolve() 
				} else {
					deferred.reject(err)
				}
			});

		return Promise.all(
			[deferred.promise].concat(
				doc.is_cleared && icdAlarmIncidentRegistry.icd_id && icdAlarmIncidentRegistry.alarm_id && icdAlarmIncidentRegistry.icd_data && icdAlarmIncidentRegistry.icd_data.system_mode ? 
					[clearPreviousAlerts(icdAlarmIncidentRegistry.icd_id, icdAlarmIncidentRegistry.alarm_id, icdAlarmIncidentRegistry.icd_data.system_mode, timestamp, timestamp)] : 
					[]
			)
		);
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

function joinICDAlarmNotificationDeliveryRule(alarm_id, system_mode) {
	return dynamoClient.get({
		TableName: util.getTableName('ICDAlarmNotificationDeliveryRule'),
		Key: { alarm_id: parseInt(alarm_id), system_mode: parseInt(system_mode) }
	})
	.promise()
	.then(result => result.Item);
}

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

function joinUserAlarmNotificationDeliveryRule(location_id, alarm_id, system_mode) {
	return dynamoClient.query({
		TableName: util.getTableName('UserAlarmNotificationDeliveryRule'),
		IndexName: 'LocationIdAlarmIdSystemModeUserIdIndex',
		KeyConditionExpression: 'location_id_alarm_id_system_mode = :location_id_alarm_id_system_mode',
		ExpressionAttributeValues: {
			':location_id_alarm_id_system_mode': `${ location_id }_${ alarm_id }_${ system_mode }`
		}
	})
	.promise()
	.then(result => result.Items);
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
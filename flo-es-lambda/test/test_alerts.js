const assert = require('chai').assert;
const uuid = require('uuid');
const proxyquire = require('proxyquire').noCallThru();
const moment = require('moment');

const models = require('./util/models');
const config = require('./config');
const esClient = require('./db/esClient');
const dynamoClient = require('./db/dynamoClient');

const alertsSchema = require('../index_schemas/alerts.json');
const startTime = moment().startOf('hour').toISOString();

describe('alerts', () => {
	var alerts;
	var util; 
	var pubsub;
	var index;
	var doctypes;

	before(done => {
		util = proxyquire('../src/util/util', {
			'../config': config
		});

		doctypes = proxyquire('../src/util/doctypes', {
			'./util': util
		});

		const Pubsub = proxyquire('../src/pubsub', {
			'./util/util': util
		});

		pubsub = new Pubsub();

		alerts = proxyquire('../src/indices/alerts', {
			'../db/esClient': esClient,
			'../db/dynamoClient': dynamoClient,
			'../util/util': util,
			'../util/doctypes': doctypes
		});

		alerts(pubsub);

		index = util.getLogIndexName('alerts', startTime);

		esClient.indices.exists({ index })
			.then(exists => {
				if (!exists) {
					return esClient.indices.create({ index, body: alertsSchema });
				} 
			})
			.then(() => done())
			.catch(done);
	});

	describe('AlarmNotificationDeliveryFilterTable', () => {
		beforeEach(function (done) {
			const account = models.createAccount();
			const location = Object.assign(
				models.createLocation(), 
				{ account_id: account.id }
			);
			const icd = Object.assign(
				models.createICD(), 
				{ location_id: location.location_id }
			);
			const icdAlarmIncidentRegistry = Object.assign(
				models.createICDAlarmIncidentRegistry(startTime),
				{ 
					icd_id: icd.id,
					account_id: account.id,
					location_id: location.location_id
				}
			);
			const alarmNotificationDeliveryFilter = Object.assign(
				models.createAlarmNotificationDeliveryFilter(startTime),
				{ 
					icd_id: icd.id,
					last_icd_alarm_incident_registry_id: icdAlarmIncidentRegistry.id
				}
			);
			const icdAlarmNotificationDeliveryRule = Object.assign(
				models.createICDAlarmNotificationDeliveryRule(),
				{ 
					alarm_id: alarmNotificationDeliveryFilter.alarm_id,
					system_mode: alarmNotificationDeliveryFilter.system_mode
				}
			);
			const userAlarmNotificationDeliveryRules = Array(1).fill(null)
				.map(() => models.createUserAlarmNotificationDeliveryRule(
					location.location_id, 
					alarmNotificationDeliveryFilter.alarm_id, 
					alarmNotificationDeliveryFilter.system_mode
				));

			Promise.all([
				dynamoClient.put({
					TableName: util.getTableName('Location'),
					Item: location
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('ICD'),
					Item: icd
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('Account'),
					Item: account
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('ICDAlarmNotificationDeliveryRule'),
					Item: icdAlarmNotificationDeliveryRule
				}).promise()
			].concat(userAlarmNotificationDeliveryRules.map(userAlarmNotificationDeliveryRule => 
				dynamoClient.put({
					TableName: util.getTableName('UserAlarmNotificationDeliveryRule'),
					Item: userAlarmNotificationDeliveryRule
				}).promise()
			)))
			.then(() => {
				this.currentTest.__data = {
					account,
					location,
					icd,
					alarmNotificationDeliveryFilter,
					icdAlarmNotificationDeliveryRule,
					icdAlarmIncidentRegistry,
					userAlarmNotificationDeliveryRules
				};
				done();
			})
			.catch(done);
		});

		it('should create a new alert type document if none exists on INSERT', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const alarmNotificationDeliveryFilter = this.test.__data.alarmNotificationDeliveryFilter;
			const icdAlarmNotificationDeliveryRule = this.test.__data.icdAlarmNotificationDeliveryRule;
			const userAlarmNotificationDeliveryRules = this.test.__data.userAlarmNotificationDeliveryRules;

			pubsub.publish(util.getTableName('AlarmNotificationDeliveryFilter'), util.EVENTS.INSERT, alarmNotificationDeliveryFilter)
				.then(() => esClient.get({ index, type: 'alert', id: alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id }))
				.then(result => {
					assert.deepEqual(
						result._source, 
						doctypes.createAlert({
							alarmNotificationDeliveryFilter,
							icdAlarmNotificationDeliveryRule,
							location,
							account,
							userAlarmNotificationDeliveryRules
						})
					);
					done();
				})
				.catch(done);
		});

		it('should update the existing alert type document on INSERT', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const alarmNotificationDeliveryFilter = this.test.__data.alarmNotificationDeliveryFilter;
			const modifiedAlarmNotificationDeliveryFilter = Object.assign(
				alarmNotificationDeliveryFilter,
				{ status: 3 }
			);
			const icdAlarmNotificationDeliveryRule = this.test.__data.icdAlarmNotificationDeliveryRule;
			const doc = doctypes.createAlert({
				alarmNotificationDeliveryFilter,
				icdAlarmNotificationDeliveryRule,
				location,
				account
			});
			const userAlarmNotificationDeliveryRules = this.test.__data.userAlarmNotificationDeliveryRules;

			esClient.index({ index, type: 'alert', id: doc.incident_id, body: doc })
				.then(() => pubsub.publish(util.getTableName('AlarmNotificationDeliveryFilter'), util.EVENTS.INSERT, modifiedAlarmNotificationDeliveryFilter))
				.then(() => esClient.get({ index, type: 'alert', id: alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id }))
				.then(result => {
					assert.deepEqual(
						result._source, 
						doctypes.createAlert({
							alarmNotificationDeliveryFilter: modifiedAlarmNotificationDeliveryFilter,
							icdAlarmNotificationDeliveryRule,
							location,
							account,
							userAlarmNotificationDeliveryRules
						})
					);
					done();
				})
				.catch(done);
		});

		it('should create a new alert type document if none exists on MODIFY', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const alarmNotificationDeliveryFilter = this.test.__data.alarmNotificationDeliveryFilter;
			const icdAlarmNotificationDeliveryRule = this.test.__data.icdAlarmNotificationDeliveryRule;
			const userAlarmNotificationDeliveryRules = this.test.__data.userAlarmNotificationDeliveryRules;

			pubsub.publish(util.getTableName('AlarmNotificationDeliveryFilter'), util.EVENTS.MODIFY, alarmNotificationDeliveryFilter)
				.then(() => esClient.get({ index, type: 'alert', id: alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id }))
				.then(result => {
					assert.deepEqual(
						result._source, 
						doctypes.createAlert({
							alarmNotificationDeliveryFilter,
							icdAlarmNotificationDeliveryRule,
							location,
							account,
							userAlarmNotificationDeliveryRules
						})
					);
					done();
				})
				.catch(done);
		});

		it('should update the existing alert type document on MODIFY', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const alarmNotificationDeliveryFilter = this.test.__data.alarmNotificationDeliveryFilter;
			const modifiedAlarmNotificationDeliveryFilter = Object.assign(
				alarmNotificationDeliveryFilter,
				{ status: 3 }
			);
			const icdAlarmNotificationDeliveryRule = this.test.__data.icdAlarmNotificationDeliveryRule;
			const doc = doctypes.createAlert({
				alarmNotificationDeliveryFilter,
				icdAlarmNotificationDeliveryRule,
				location,
				account
			});
			const userAlarmNotificationDeliveryRules = this.test.__data.userAlarmNotificationDeliveryRules;

			esClient.index({ index, type: 'alert', id: doc.incident_id, body: doc })
				.then(() => pubsub.publish(util.getTableName('AlarmNotificationDeliveryFilter'), util.EVENTS.MODIFY, modifiedAlarmNotificationDeliveryFilter))
				.then(() => esClient.get({ index, type: 'alert', id: alarmNotificationDeliveryFilter.last_icd_alarm_incident_registry_id }))
				.then(result => {
					assert.deepEqual(
						result._source, 
						doctypes.createAlert({
							alarmNotificationDeliveryFilter: modifiedAlarmNotificationDeliveryFilter,
							icdAlarmNotificationDeliveryRule,
							location,
							account,
							userAlarmNotificationDeliveryRules
						})
					);
					done();
				})
				.catch(done);
		});
	});

	describe('ICDAlarmIncidentRegistryTable', () => {
		beforeEach(function () {
			const account = models.createAccount();
			const location = Object.assign(
				models.createLocation(), 
				{ account_id: account.id }
			);
			const icd = Object.assign(
				models.createICD(), 
				{ location_id: location.location_id }
			);
			const icdAlarmIncidentRegistry = Object.assign(
				models.createICDAlarmIncidentRegistry(startTime),
				{ 
					icd_id: icd.id,
					account_id: account.id,
					location_id: location.location_id,
				}
			);
			const alarmNotificationDeliveryFilter = Object.assign(
				models.createAlarmNotificationDeliveryFilter(icdAlarmIncidentRegistry.incident_time),
				{ 
					icd_id: icd.id,
					last_icd_alarm_incident_registry_id: icdAlarmIncidentRegistry.id
				}
			);
			const icdAlarmNotificationDeliveryRule = Object.assign(
				models.createICDAlarmNotificationDeliveryRule(),
				{ 
					alarm_id: alarmNotificationDeliveryFilter.alarm_id,
					system_mode: alarmNotificationDeliveryFilter.system_mode
				}
			);

			this.currentTest.__data = {
				account,
				location,
				icd,
				alarmNotificationDeliveryFilter,
				icdAlarmNotificationDeliveryRule,
				icdAlarmIncidentRegistry
			};
		});

		it('should update the existing alert document on MODIFY', function (done) {
			const icdAlarmIncidentRegistry = this.test.__data.icdAlarmIncidentRegistry;
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const alarmNotificationDeliveryFilter = this.test.__data.alarmNotificationDeliveryFilter;
			const icdAlarmNotificationDeliveryRule = this.test.__data.icdAlarmNotificationDeliveryRule;
			const doc = doctypes.createAlert({
				alarmNotificationDeliveryFilter,
				icdAlarmNotificationDeliveryRule,
				location,
				account
			});

			esClient.index({ index, type: 'alert', id: icdAlarmIncidentRegistry.id, body: doc })
				.then(() => pubsub.publish(util.getTableName('ICDAlarmIncidentRegistry'), util.EVENTS.MODIFY, icdAlarmIncidentRegistry))
				.then(() => esClient.get({ index, type: 'alert', id: icdAlarmIncidentRegistry.id }))
				.then(result => {
					assert.deepEqual(
						result._source,
						doctypes.createAlert({
							icdAlarmIncidentRegistry,
							alarmNotificationDeliveryFilter,
							icdAlarmNotificationDeliveryRule,
							location,
							account
						})
					);
					done();
				})
				.catch(done);
		});

		it('should not error if no alert document exists on MODIFY', function (done) {
			const icdAlarmIncidentRegistry = this.test.__data.icdAlarmIncidentRegistry;

			pubsub.publish(util.getTableName('ICDAlarmIncidentRegistry'), util.EVENTS.MODIFY, icdAlarmIncidentRegistry)
				.then(() => {
					esClient.get({ index, type: 'alert', id: icdAlarmIncidentRegistry.id })
						.then(result => {
							assert.isOk(false);
							done();
						})
						.catch(err => {
							if (err.status === 404) {
								assert.isOk(true);
								done();
							} else {
								done(err);
							}
						});
				})
				.catch(done);
		});

		it('should clear the alerts if acknowledged_by_user is set', function (done) {
			const alarmNotificationDeliveryFilter = Object.assign(
				this.test.__data.alarmNotificationDeliveryFilter,
				{ status: 3 }
			);
			const icdAlarmIncidentRegistry = Object.assign(
				this.test.__data.icdAlarmIncidentRegistry,
				{ acknowledged_by_user: 1 }
			);
			const doc = doctypes.createAlert({ alarmNotificationDeliveryFilter });

			esClient.index({ index, type: 'alert', id: doc.incident_id, body: doc })
				.then(() => pubsub.publish(util.getTableName('ICDAlarmIncidentRegistry'), util.EVENTS.MODIFY, icdAlarmIncidentRegistry))
				.then(() => esClient.get({ index, type: 'alert', id: icdAlarmIncidentRegistry.id }))
				.then(result => {
					assert.deepEqual(
						{ acknowledged_by_user: result._source.acknowledged_by_user, is_cleared: result._source.is_cleared },
						{ acknowledged_by_user: 1, is_cleared: true }
					);
					done();
				})
				.catch(done);
		});

		it('should clear previous alerts if this alert is cleared', function (done) {
			const alarmNotificationDeliveryFilter = Object.assign(
				{},
				this.test.__data.alarmNotificationDeliveryFilter,
				{ status: 3 }
			);
			const icdAlarmIncidentRegistry = Object.assign(
				{},
				this.test.__data.icdAlarmIncidentRegistry,
				{ acknowledged_by_user: 1 }
			);
			const previousAlarmNotificationDeliveryFilter = Object.assign(
				{},
				alarmNotificationDeliveryFilter,
				{ 
					last_icd_alarm_incident_registry_id: uuid.v4(),
					incident_time: moment(alarmNotificationDeliveryFilter.incident_time).subtract(10, 'minutes').toISOString()
				}
			);
			const doc = doctypes.createAlert({ alarmNotificationDeliveryFilter });
			const prevDoc = doctypes.createAlert({ alarmNotificationDeliveryFilter: previousAlarmNotificationDeliveryFilter });

			esClient.bulk({
				refresh: true,
				body: [
					{ index: { _index: index, _type: 'alert', _id: doc.incident_id } },
					doc,
					{ index: { _index: index, _type: 'alert', _id: prevDoc.incident_id } },
					prevDoc
				]
			})
			.then(() => pubsub.publish(util.getTableName('ICDAlarmIncidentRegistry'), util.EVENTS.MODIFY, icdAlarmIncidentRegistry))
			.then(() => esClient.mget({ 
				body: {
					docs: [
						{ _index: index, _type: 'alert', _id: doc.incident_id },
						{ _index: index, _type: 'alert', _id: prevDoc.incident_id }
					]
				}
			}))
			.then(result => {
				assert.deepEqual(
					result.docs.map(resultDoc => ({ acknowledged_by_user: resultDoc._source.acknowledged_by_user, is_cleared: resultDoc._source.is_cleared })),
					[{ acknowledged_by_user: 1, is_cleared: true }, { acknowledged_by_user: 1, is_cleared: true }]
				);
				done();
			})
			.catch(done);

		});
	});
});

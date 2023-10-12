const assert = require('chai').assert;
const uuid = require('uuid');
const proxyquire = require('proxyquire').noCallThru();
const moment = require('moment');

const models = require('./util/models');
const config = require('./config');
const esClient = require('./db/esClient');
const dynamoClient = require('./db/dynamoClient');

const icdalarmincidentregistrylogsSchema = require('../index_schemas/icdalarmincidentregistrylogs.json');
const startTime = moment().startOf('hour').toISOString();

describe('icdalarmincidentregistrylogs', () => {
	var icdalarmincidentregistrylogs;
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

		icdalarmincidentregistrylogs = proxyquire('../src/indices/icdalarmincidentregistrylogs', {
			'../db/esClient': esClient,
			'../db/dynamoClient': dynamoClient,
			'../util/util': util,
			'../util/doctypes': doctypes
		});

		icdalarmincidentregistrylogs(pubsub);

		index = util.getLogIndexName('icdalarmincidentregistrylogs', startTime);

		esClient.indices.exists({ index })
			.then(exists => {
				if (!exists) {
					return esClient.indices.create({ index, body: icdalarmincidentregistrylogsSchema });
				} 
			})
			.then(() => done())
			.catch(done);
	});

	describe('ICDAlarmIncidentRegistryLogTable', () => {
		beforeEach(function (done) {
			const account = models.createAccount();
			const location = Object.assign(
				models.createLocation(),
				{ account_id: account.id } 
			);
			const icdAlarmIncidentRegistry = Object.assign(
				models.createICDAlarmIncidentRegistry(startTime),
				{ 
					account_id: account.id,
					location_id: location.location_id
				}
			);
			const icdAlarmIncidentRegistryLog = Object.assign(
				models.createICDAlarmIncidentRegistryLog(startTime),
				{ icd_alarm_incident_registry_id: icdAlarmIncidentRegistry.id }
			);

			Promise.all([
				dynamoClient.put({
					TableName: util.getTableName('Account'),
					Item: account
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('Location'),
					Item: location
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('ICDAlarmIncidentRegistry'),
					Item: icdAlarmIncidentRegistry
				}).promise()
			])
			.then(() => {
				this.currentTest.__data = {
					account,
					location,
					icdAlarmIncidentRegistry,
					icdAlarmIncidentRegistryLog
				};
				done();
			})
			.catch(done);
		});

		it('should create a new icdalarmincidentregistrylog type document on INSERT', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const icdAlarmIncidentRegistryLog = this.test.__data.icdAlarmIncidentRegistryLog;

			pubsub.publish(util.getTableName('ICDAlarmIncidentRegistryLog'), util.EVENTS.INSERT, icdAlarmIncidentRegistryLog)
				.then(() => esClient.get({ index, type: 'icdalarmincidentregistrylog', id: icdAlarmIncidentRegistryLog.id }))
				.then(result => {
					assert.deepEqual(
						result._source, 
						doctypes.createICDAlarmIncidentRegistryLog(
							icdAlarmIncidentRegistryLog,
							account,
							location
						)
					);
					done();
				})
				.catch(done);
		});
	});
});
const assert = require('chai').assert;
const uuid = require('uuid');
const proxyquire = require('proxyquire').noCallThru();
const moment = require('moment');

const models = require('./util/models');
const config = require('./config');
const esClient = require('./db/esClient');
const dynamoClient = require('./db/dynamoClient');

const icdalarmincidentregistriesSchema = require('../index_schemas/icdalarmincidentregistries.json');
const startTime = moment().startOf('hour').toISOString();

describe('icdalarmincidentregistries', () => {
	var icdalarmincidentregistries;
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

		icdalarmincidentregistries = proxyquire('../src/indices/icdalarmincidentregistries', {
			'../db/esClient': esClient,
			'../db/dynamoClient': dynamoClient,
			'../util/util': util,
			'../util/doctypes': doctypes
		});

		icdalarmincidentregistries(pubsub);

		index = util.getLogIndexName('icdalarmincidentregistries', startTime);

		esClient.indices.exists({ index })
			.then(exists => {
				if (!exists) {
					return esClient.indices.create({ index, body: icdalarmincidentregistriesSchema });
				} 
			})
			.then(() => done())
			.catch(done);
	});

	describe('ICDAlarmIncidentRegistryTable', () => {
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
					TableName: util.getTableName('ICD'),
					Item: icd
				}).promise()
			])
			.then(() => {
				this.currentTest.__data = {
					account,
					location,
					icd,
					icdAlarmIncidentRegistry
				};

				done();
			})
			.catch(done);
		});

		it('should create a new icdalarmincidentregistry type document on INSERT', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const icdAlarmIncidentRegistry = this.test.__data.icdAlarmIncidentRegistry;

			pubsub.publish(util.getTableName('ICDAlarmIncidentRegistry'), util.EVENTS.INSERT, icdAlarmIncidentRegistry)
				.then(() => esClient.get({ index, type: 'icdalarmincidentregistry', id: icdAlarmIncidentRegistry.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICDAlarmIncidentRegistry(icdAlarmIncidentRegistry, account, location));
					done();
				})
				.catch(done);
		});

		it('should create a new icdalarmincidentregistry type document if none exists on MODIFY', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const icdAlarmIncidentRegistry = this.test.__data.icdAlarmIncidentRegistry;

			pubsub.publish(util.getTableName('ICDAlarmIncidentRegistry'), util.EVENTS.MODIFY, icdAlarmIncidentRegistry)
				.then(() => esClient.get({ index, type: 'icdalarmincidentregistry', id: icdAlarmIncidentRegistry.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICDAlarmIncidentRegistry(icdAlarmIncidentRegistry, account, location));
					done();
				})
				.catch(done);
		});

		it('should update the existing icdalarmincidentregistry type document on MODIFY', function (done) {
			const account = this.test.__data.account;
			const location = this.test.__data.location;
			const modifiedICDAlarmIncidentRegistry = this.test.__data.icdAlarmIncidentRegistry;
			const icdAlarmIncidentRegistry = Object.assign(modifiedICDAlarmIncidentRegistry, { user_action_taken: {} });
			const icdAlarmIncidentRegistryDoc = doctypes.createICDAlarmIncidentRegistry(icdAlarmIncidentRegistry, account, location);

			esClient.index({ index, type: 'icdalarmincidentregistry', id: icdAlarmIncidentRegistry.id, body: icdAlarmIncidentRegistryDoc })
				.then(() => pubsub.publish(util.getTableName('ICDAlarmIncidentRegistry'), util.EVENTS.MODIFY, modifiedICDAlarmIncidentRegistry))
				.then(() => esClient.get({ index, type: 'icdalarmincidentregistry', id: icdAlarmIncidentRegistryDoc.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICDAlarmIncidentRegistry(modifiedICDAlarmIncidentRegistry, account, location));
					done();
				})
				.catch(done);
		});
	});
});	
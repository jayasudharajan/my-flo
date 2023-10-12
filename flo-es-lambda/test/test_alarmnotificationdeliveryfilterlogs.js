const assert = require('chai').assert;
const uuid = require('uuid');
const proxyquire = require('proxyquire').noCallThru();
const moment = require('moment');

const models = require('./util/models');
const config = require('./config');
const esClient = require('./db/esClient');
const dynamoClient = require('./db/dynamoClient');

const alarmnotificationdeliveryfilterlogsSchema = require('../index_schemas/alarmnotificationdeliveryfilterlogs.json');
const startTime = moment().startOf('hour').toISOString();

describe('alarmnotificationdeliveryfilterlogs', () => {
	var alarmnotificationdeliveryfilterlogs;
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

		alarmnotificationdeliveryfilterlogs = proxyquire('../src/indices/alarmnotificationdeliveryfilterlogs', {
			'../db/esClient': esClient,
			'../db/dynamoClient': dynamoClient,
			'../util/util': util,
			'../util/doctypes': doctypes
		});

		alarmnotificationdeliveryfilterlogs(pubsub);

		index = util.getLogIndexName('alarmnotificationdeliveryfilterlogs', startTime);

		esClient.indices.exists({ index })
			.then(exists => {
				if (!exists) {
					return esClient.indices.create({ index, body: alarmnotificationdeliveryfilterlogsSchema });
				} 
			})
			.then(() => done())
			.catch(done);
	});

	describe('AlarmNotificationDeliveryRuleTable', () => {

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
			const alarmNotificationDeliveryFilter = Object.assign(
				models.createAlarmNotificationDeliveryFilter(startTime),
				{ icd_id: icd.id }
			);

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
				})
				.promise()
			])
			.then(() => {
				this.currentTest.__data = {
					account,
					location,
					icd,
					alarmNotificationDeliveryFilter
				};
				done();
			})
			.catch(done);
		});

		it('should create a new alarmnotificationdeliveryfilterlog type document on INSERT', function (done) {
			const location = this.test.__data.location;
			const account = this.test.__data.account;
			const alarmNotificationDeliveryFilter = this.test.__data.alarmNotificationDeliveryFilter;

			pubsub.publish(util.getTableName('AlarmNotificationDeliveryFilter'), util.EVENTS.INSERT, alarmNotificationDeliveryFilter)
				.then(result =>
					esClient.get({ 
						index, 
						type: 'alarmnotificationdeliveryfilterlog',
						id: result[0]._id
					})
				)
				.then(result => {
					assert.deepEqual(
						result._source,
						doctypes.createAlarmNotificationDeliveryFilterLog(alarmNotificationDeliveryFilter, account, location)
					);
					done();
				})
				.catch(done);
		});

		it('should create a new alarmnotificationdeliveryfilterlog type document on MODIFY', function (done) {
			const location = this.test.__data.location;
			const account = this.test.__data.account;
			const alarmNotificationDeliveryFilter = this.test.__data.alarmNotificationDeliveryFilter;
			const alarmNotificationDeliveryFilterDoc = doctypes.createAlarmNotificationDeliveryFilterLog(alarmNotificationDeliveryFilter, account, location);
			const modifiedAlarmNotificationDeliveryFilter = Object.assign(
				{},
				alarmNotificationDeliveryFilter,
				{ status: 3, updated_at: moment(alarmNotificationDeliveryFilter.updated_at).add(5, 'minutes').toISOString() }
			);

			esClient.index({ index, type: 'alarmnotificationdeliveryfilterlog', body: alarmNotificationDeliveryFilterDoc })
				.then(result => Promise.all([
					new Promise(resolve => resolve(result)),
					pubsub.publish(util.getTableName('AlarmNotificationDeliveryFilter'), util.EVENTS.MODIFY, modifiedAlarmNotificationDeliveryFilter)
				]))
				.then(results => 
					esClient.mget({ 
						index, 
						type: 'alarmnotificationdeliveryfilterlog',
						body: {
							ids: [results[0]._id, results[1][0]._id]
						}
					})
				)
				.then(result => {
					assert.deepEqual(
						result.docs.map(doc => doc._source),
						[
							alarmNotificationDeliveryFilterDoc,
							doctypes.createAlarmNotificationDeliveryFilterLog(modifiedAlarmNotificationDeliveryFilter, account, location) 
						]
					);
					done();
				})
				.catch(done);
		});
	});
});


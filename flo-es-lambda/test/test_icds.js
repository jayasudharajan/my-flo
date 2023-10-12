const assert = require('chai').assert;
const uuid = require('uuid');
const proxyquire = require('proxyquire').noCallThru();

const models = require('./util/models');
const config = require('./config');
const esClient = require('./db/esClient');
const dynamoClient = require('./db/dynamoClient');

const icdsSchema = require('../index_schemas/icds.json');

describe('icds', () => {
	var icds;
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

		icds = proxyquire('../src/indices/icds', {
			'../db/esClient': esClient,
			'../db/dynamoClient': dynamoClient,
			'../util/util': util,
			'../util/doctypes': doctypes
		});

		icds(pubsub);

		esClient.indices.exists({ index: 'icds' })
			.then(exists => {
				if (!exists) {
					return esClient.indices.create({ index: 'icds', body: icdsSchema });
				} 
			})
			.then(() => done())
			.catch(done);
	});

	describe('ICDTable', () => {

		it('should create a new icd type document if none exists on INSERT', done => {
			const icd = models.createICD();

			pubsub.publish(util.getTableName('ICD'), util.EVENTS.INSERT, icd)
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd }));
					done();
				})
				.catch(done);
		});

		it('should modify the existing icd type document on INSERT', done => {
			const icd = models.createICD();
			const modifiedICD = Object.assign({}, icd, { is_paired: false });

			esClient.index({ index: 'icds', type: 'icd', id: icd.id, body: doctypes.createICD({ icd })})
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.INSERT, modifiedICD))
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd: modifiedICD }));
					done();
				})
				.catch(done);
		});

		it('should create a new icd type document if none exists on MODIFY', done => {
			const icd = models.createICD();

			pubsub.publish(util.getTableName('ICD'), util.EVENTS.MODIFY, icd)
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd }));
					done();
				})
				.catch(done);
		});

		it('should modify the existing icd type document on MODIFY', done => {
			const icd = models.createICD();
			const modifiedICD = Object.assign({}, icd, { is_paired: false });

			esClient.index({ index: 'icds', type: 'icd', id: icd.id, body: doctypes.createICD({ icd })})
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.MODIFY, modifiedICD))
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd: modifiedICD }));
					done();
				})
				.catch(done);
		});

		it('should delete the existing icd type document on REMOVE', done => {
			const icd = models.createICD();

			esClient.index({ index: 'icds', type: 'icd', id: icd.id, body: doctypes.createICD({ icd })})
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.REMOVE, icd))
				.then(() => esClient.exists({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.isOk(!result);
					done();
				})
				.catch(done);
		});

		it('should not error if no icd type document exists on REMOVE', done => {
			const icd = models.createICD();

			pubsub.publish(util.getTableName('ICD'), util.EVENTS.REMOVE, icd)
				.then(() => {
					assert.isOk(true);
					done();
				})
				.catch(err => {
					if (err.status === 404) {
						assert.isOk(false);
						done();
					} else {
						done(err);
					}
				});
		});


	});

	describe('LocationTable', () => {
		beforeEach(function (done) {
			const location = models.createLocation();
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });

			dynamoClient.put({
				TableName: util.getTableName('ICD'),
				Item: icd
			})
			.promise()
			.then(() => {
				this.currentTest.__data = { location, icd };
				done();
			})
			.catch(done);
		});

		it('should create a new icd type document on INSERT', function (done) {
			const icd = this.test.__data.icd;
			const location = this.test.__data.location;

			pubsub.publish(util.getTableName('Location'), util.EVENTS.INSERT, location)
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ location }));
					done();
				})
				.catch(done);
		});

		it('should update the existing ICD type document on INSERT', function (done) {
			const icd = this.test.__data.icd;
			const location = this.test.__data.location;

			esClient.index({ index: 'icds', type: 'icd', id: icd.id, body: doctypes.createICD({ icd }) })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.INSERT, location))
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd, location }));
					done();
				})
				.catch(done);
		});

		it('should create a new icd type document if none exists on MODIFY', function (done) {
			const icd = this.test.__data.icd;
			const location = this.test.__data.location;

			pubsub.publish(util.getTableName('Location'), util.EVENTS.MODIFY, location)
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ location }));
					done();
				})
				.catch(done);
		});

		it('should update the existing ICD type document on MODIFY', function (done) {
			const icd = this.test.__data.icd;
			const location = this.test.__data.location;

			esClient.index({ index: 'icds', type: 'icd', id: icd.id, body: doctypes.createICD({ icd }) })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.MODIFY, location))
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd, location }));
					done();
				})
				.catch(done);
		});
	});

	describe('AccountTable', () => {
		beforeEach(function (done) {
			const account = models.createAccount();
			const location = Object.assign(models.createLocation(), { account_id: account.id });
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });

			Promise.all([
				dynamoClient.put({
					TableName: util.getTableName('ICD'),
					Item: icd
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('Location'),
					Item: location
				}).promise()
			])
			.then(() => {
				this.currentTest.__data = { location, icd, account };
				done();
			})
			.catch(done);
		});

		it('should create a new icd type document on INSERT', function (done) {
			const icd = this.test.__data.icd;
			const account = this.test.__data.account;

			pubsub.publish(util.getTableName('Account'), util.EVENTS.INSERT, account)
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ account }));
					done();
				})
				.catch(done);
		});

		it('should update the existing ICD type document on INSERT', function (done) {
			const icd = this.test.__data.icd;
			const account = this.test.__data.account;

			esClient.index({ index: 'icds', type: 'icd', id: icd.id, body: doctypes.createICD({ icd }) })
				.then(() => pubsub.publish(util.getTableName('Account'), util.EVENTS.INSERT, account))
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd, account }));
					done();
				})
				.catch(done);
		});

		it('should create a new icd type document if none exists on MODIFY', function (done) {
			const icd = this.test.__data.icd;
			const account = this.test.__data.account;

			pubsub.publish(util.getTableName('Account'), util.EVENTS.MODIFY, account)
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ account }));
					done();
				})
				.catch(done);
		});

		it('should update the existing ICD type document on MODIFY', function (done) {
			const icd = this.test.__data.icd;
			const account = this.test.__data.account;

			esClient.index({ index: 'icds', type: 'icd', id: icd.id, body: doctypes.createICD({ icd }) })
				.then(() => pubsub.publish(util.getTableName('Account'), util.EVENTS.MODIFY, account))
				.then(() => esClient.get({ index: 'icds', type: 'icd', id: icd.id }))
				.then(result => {
					assert.deepEqual(result._source, doctypes.createICD({ icd, account }));
					done();
				})
				.catch(done);
		});
	});
});
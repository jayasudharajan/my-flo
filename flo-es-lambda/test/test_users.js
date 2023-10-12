const assert = require('chai').assert;
const uuid = require('uuid');
const _ = require('lodash');
const proxyquire = require('proxyquire').noCallThru();

const models = require('./util/models');
const config = require('./config');
const esClient = require('./db/esClient');
const dynamoClient = require('./db/dynamoClient');

const createUser = models.createUser;
const createUserDetail = models.createUserDetail;
const createLocation = models.createLocation;
const createAccount = models.createAccount;

const usersIndexSchema = require('../index_schemas/users.json');

describe('users', () => {
	var users;
	var util; 
	var pubsub;

	before(done => {
		util = proxyquire('../src/util/util', {
			'../config': config
		});

		const Pubsub = proxyquire('../src/pubsub', {
			'./util/util': util
		});

		pubsub = new Pubsub();

		users = proxyquire('../src/indices/users', {
			'../db/esClient': esClient,
			'../db/dynamoClient': dynamoClient,
			'../util/util': util
		});

		users(pubsub);

		esClient.indices.exists({ index: 'users' })
			.then(exists => {
				if (!exists) {
					return esClient.indices.create({ index: 'users', body: usersIndexSchema });
				} 
			})
			.then(() => done())
			.catch(done);
	});

	describe('UserTable', () => {
		it('should insert a new user type document if none exists on INSERT', done => {
			const user = createUser();

			pubsub.publish(util.getTableName('User'), util.EVENTS.INSERT, user)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source, user);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on INSERT', done => {
			const user = createUser();
			const modifiedUser = Object.assign({}, user, { email: 'test+foo@flotechnologies.com' });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('User'), util.EVENTS.INSERT, modifiedUser))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source, modifiedUser);
					done();
				})
				.catch(done);
		});

		it('should insert a new user type document if none exists on MODIFY', done => {
			const user = createUser();

			pubsub.publish(util.getTableName('User'), util.EVENTS.MODIFY, user)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source, user);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on MODIFY', done => {
			const user = createUser();
			const modifiedUser = Object.assign({}, user, { email: 'test+foo@flotechnologies.com' });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('User'), util.EVENTS.MODIFY, modifiedUser))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source, modifiedUser);
					done();
				})
				.catch(done);
		});

		it('should delete the existing user type document on REMOVE', done => {
			const user = createUser();

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('User'), util.EVENTS.REMOVE, user))
				.then(() => esClient.exists({ index: 'users', type: 'user', id: user.id }))
				.then(exists => {
					assert.isOk(!exists);
					done();
				})
				.catch(done);
		});

		it('should not error if no user type document exists on REMOVE', done => {
			const user = createUser();

			pubsub.publish(util.getTableName('User'), util.EVENTS.REMOVE, user)
				.then(() => esClient.exists({ index: 'users', type: 'user', id: user.id }))
				.then(exists => {
					assert.isOk(!exists);
					done();
				})
				.catch(done);
		});
	});

	describe('UserDetailTable', () => {
		const userDetailProps = ['firstname', 'lastname', 'phone_mobile'];

		it('should create a new user type document if none exists on INSERT', done => {
			const userDetail = createUserDetail();

			pubsub.publish(util.getTableName('UserDetail'), util.EVENTS.INSERT, userDetail)
				.then(() => esClient.get({ index: 'users', type: 'user', id: userDetail.user_id }))
				.then(result => {
					assert.deepEqual(
						_.pick(result._source, userDetailProps), 
						_.pick(userDetail, userDetailProps)
					);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on INSERT', done => {
			const user = createUser();
			const userDetail = Object.assign(createUserDetail(), { user_id: user.id });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('UserDetail'), util.EVENTS.INSERT, userDetail))
				.then(() => esClient.get({ index: 'users', type: 'user', id: userDetail.user_id }))
				.then(result => {
					assert.deepEqual(
						_.pick(result._source, userDetailProps),
						_.pick(userDetail, userDetailProps)
					);
					done();
				})
				.catch(done);
		});

		it('should create a new user type document if none exists on MODIFY', done => {
			const userDetail = createUserDetail();

			pubsub.publish(util.getTableName('UserDetail'), util.EVENTS.MODIFY, userDetail)
				.then(() => esClient.get({ index: 'users', type: 'user', id: userDetail.user_id }))
				.then(result => {
					assert.deepEqual(
						_.pick(result._source, userDetailProps), 
						_.pick(userDetail, userDetailProps)
					);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on MODIFY', done => {
			const user = createUser();
			const userDetail = Object.assign(createUserDetail(), { user_id: user.id });
			const modifiedUserDetail = Object.assign({}, userDetail, { firstname: 'Henry' });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign(_.pick(userDetail, userDetailProps), user) })
				.then(() => pubsub.publish(util.getTableName('UserDetail'), util.EVENTS.MODIFY, modifiedUserDetail))
				.then(() => esClient.get({ index: 'users', type: 'user', id: userDetail.user_id }))
				.then(result => {
					assert.deepEqual(
						_.pick(result._source, userDetailProps),
						_.pick(modifiedUserDetail, userDetailProps)
					);
					done();
				})
				.catch(done);
		});

		it('should not change the existing user type document on REMOVE', done => {
			const user = createUser();
			const userDetail = Object.assign(createUserDetail(), { user_id: user.id });
			const userDoc = Object.assign({}, user, _.pick(userDetail, userDetailProps));

			esClient.index({ index: 'users', type: 'user', id: user.id, body: userDoc })
				.then(() => pubsub.publish(util.getTableName('UserDetail'), util.EVENTS.REMOVE, userDetail))
				.then(() => esClient.get({ index: 'users', type: 'user', id: userDetail.user_id }))
				.then(result => {
					assert.deepEqual(result._source, userDoc);
					done();
				})
				.catch(done);
		});

		it('should not error if no user type document exists on REMOVE', done => {
			const userDetail = createUserDetail();

			pubsub.publish(util.getTableName('UserDetail'), util.EVENTS.REMOVE, userDetail)
				.then(() => {
					assert.isOk(true);
					done();
				})
				.catch(err => {
					assert.isOk(false);
					done(err);
				});
		});
	});

	describe('LocationTable', () => {
		beforeEach(function (done) {
			const user = createUser();
			const location = createLocation();
			const userLocationRole = {
				user_id: user.id,
				location_id: location.location_id
			};

			Promise.all([
				dynamoClient.put({
					TableName: util.getTableName('User'),
					Item: user
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('UserLocationRole'),
					Item: userLocationRole
				}).promise()
			])
			.then(() => {
				this.currentTest.__data = { user, location };
				done();
			})
			.catch(done);
		});

		it('should create a new user type document if none exists on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;

			pubsub.publish(util.getTableName('Location'), util.EVENTS.INSERT, location)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.includeDeepMembers(result._source.geo_locations, [util.createGeoLocation(location)]);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.INSERT, location))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.includeDeepMembers(result._source.geo_locations, [util.createGeoLocation(location)]);
					done();
				})
				.catch(done);
		});

		it('should append a new geo_location to the existing user type document on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const geo_location = util.createGeoLocation(createLocation());

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ geo_locations: [geo_location] }, user) })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.INSERT, location))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.geo_locations, [geo_location, util.createGeoLocation(location)]);
					done();
				})
				.catch(done);
		});

		it('should replace the geo_location of the existing user type document on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const geo_location = util.createGeoLocation(location);
			const modifiedLocation = Object.assign({}, location, { postalcode: '90067' });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ geo_locations: [geo_location] }, user) })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.INSERT, modifiedLocation))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.geo_locations, [util.createGeoLocation(modifiedLocation)]);
					done();
				})
				.catch(done);
		});

		it('should create a new user type document if none exists on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;

			pubsub.publish(util.getTableName('Location'), util.EVENTS.MODIFY, location)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.geo_locations, [util.createGeoLocation(location)]);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.MODIFY, location))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.geo_locations, [util.createGeoLocation(location)]);
					done();
				})
				.catch(done);
		});

		it('should append a new geo_location to the existing user type document on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const geo_location = util.createGeoLocation(createLocation());

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ geo_locations: [geo_location] }, user) })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.MODIFY, location))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.geo_locations, [geo_location, util.createGeoLocation(location)]);
					done();
				})
				.catch(done);
		});

		it('should replace the geo_location of the existing user type document on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const geo_location = util.createGeoLocation(location);
			const modifiedLocation = Object.assign({}, location, { postalcode: '90067' });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ geo_locations: [geo_location] }, user) })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.MODIFY, modifiedLocation))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.geo_locations, [util.createGeoLocation(modifiedLocation)]);
					done();
				})
				.catch(done);
		});

		it('should remove the geo_location of the existing user type document on REMOVE', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const geo_location = util.createGeoLocation(location);

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ geo_locations: [geo_location] }, user) })
				.then(() => pubsub.publish(util.getTableName('Location'), util.EVENTS.REMOVE, location))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.isOk(!result._source.geo_locations || !result._source.geo_locations.length);
					done();
				})
				.catch(done);

		});
	});

	describe('AccountTable', () => {
		beforeEach(function (done) {
			const user = createUser();
			const account = createAccount();
			const userAccountRole = {
				user_id: user.id,
				account_id: account.id
			};

			Promise.all([
				dynamoClient.put({
					TableName: util.getTableName('User'),
					Item: user
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('UserAccountRole'),
					Item: userAccountRole
				}).promise()
			])
			.then(() => {
				this.currentTest.__data = { user, account };
				done();
			})
			.catch(done);
		});

		it('should create a new user type document if none exists on INSERT', function (done) {
			const user = this.test.__data.user;
			const account = this.test.__data.account;

			pubsub.publish(util.getTableName('Account'), util.EVENTS.INSERT, account)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source, { account: util.createAccount(account) });
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on INSERT', function (done) {
			const user = this.test.__data.user;
			const account = this.test.__data.account;

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('Account'), util.EVENTS.INSERT, account))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(
						result._source, 
						Object.assign({ account: util.createAccount(account) }, user)
					);
					done();
				})
				.catch(done);
		});

		it('should create a new user type document if none exists on MODIFY', function (done) {
			const user = this.test.__data.user;
			const account = this.test.__data.account;

			pubsub.publish(util.getTableName('Account'), util.EVENTS.MODIFY, account)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source, { account: util.createAccount(account) });
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on MODIFY', function (done) {
			const user = this.test.__data.user;
			const account = this.test.__data.account;
			const modifiedAccount = Object.assign({}, account, { group_id: uuid.v4() });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ account: util.createAccount(account) }, user) })
				.then(() => pubsub.publish(util.getTableName('Account'), util.EVENTS.MODIFY, modifiedAccount))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(
						result._source, 
						Object.assign(
							{ account: util.createAccount(modifiedAccount) },
							user
						)
					);
					done();
				})
				.catch(done);
		});

		it('should not change the existing user type document on REMOVE', function (done) {
			const user = this.test.__data.user;
			const account = this.test.__data.account;
			const userDoc = Object.assign({ account: util.createAccount(account) }, user);

			esClient.index({ index: 'users', type: 'user', id: user.id, body: userDoc })
				.then(() => pubsub.publish(util.getTableName('Account'), util.EVENTS.REMOVE, account))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source, userDoc);
					done();
				})
				.catch(done);
		});

		it('should not error if no user type document exists on REMOVE', function (done) {
			const account = createAccount();

			pubsub.publish(util.getTableName('Account'), util.EVENTS.REMOVE, account)
				.then(() => {
					assert.isOk(true);
					done();
				})
				.catch(err => {
					assert.isOk(false);
					done(err);
				});
		});

	});

	describe('ICDTable', () => {
		beforeEach(function (done) {
			const user = createUser();
			const location = createLocation();
			const userLocationRole = {
				user_id: user.id,
				location_id: location.location_id
			};

			Promise.all([
				dynamoClient.put({
					TableName: util.getTableName('User'),
					Item: user
				}).promise(),
				dynamoClient.put({
					TableName: util.getTableName('UserLocationRole'),
					Item: userLocationRole
				}).promise()
			])
			.then(() => {
				this.currentTest.__data = { user, location };
				done();
			})
			.catch(done);
		});

		it('should create a new user type document if none exists on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });

			pubsub.publish(util.getTableName('ICD'), util.EVENTS.INSERT, icd)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.includeDeepMembers(result._source.devices, [icd]);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.INSERT, icd))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.includeDeepMembers(result._source.devices, [icd]);
					done();
				})
				.catch(done);
		});

		it('should append a new icd to the existing user type document on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd1 = Object.assign(models.createICD(), { location_id: location.location_id });
			const icd2 = Object.assign(models.createICD(), { location_id: location.location_id });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ devices: [icd1] }, user) })
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.INSERT, icd2))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.devices, [icd1, icd2]);
					done();
				})
				.catch(done);
		});

		it('should replace the icd of the existing user type document on INSERT', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });
			const modifiedICD = Object.assign({}, icd, { is_paired: false });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ devices: [icd] }, user) })
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.INSERT, modifiedICD))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.devices, [modifiedICD]);
					done();
				})
				.catch(done);
		});

		it('should create a new user type document if none exists on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });

			pubsub.publish(util.getTableName('ICD'), util.EVENTS.MODIFY, icd)
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.devices, [icd]);
					done();
				})
				.catch(done);
		});

		it('should update the existing user type document on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: user })
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.MODIFY, icd))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.devices, [icd]);
					done();
				})
				.catch(done);
		});

		it('should append a new icd to the existing user type document on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd1 = Object.assign(models.createICD(), { location_id: location.location_id });
			const icd2 = Object.assign(models.createICD(), { location_id: location.location_id });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ devices: [icd1] }, user) })
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.MODIFY, icd2))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.devices, [icd1, icd2]);
					done();
				})
				.catch(done);
		});

		it('should replace the icd of the existing user type document on MODIFY', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });
			const modifiedICD = Object.assign({}, icd, { is_paired: false });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ devices: [icd] }, user) })
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.INSERT, modifiedICD))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.deepEqual(result._source.devices, [modifiedICD]);
					done();
				})
				.catch(done);
		});

		it('should remove the icd of the existing user type document on REMOVE', function (done) {
			const user = this.test.__data.user;
			const location = this.test.__data.location;
			const icd = Object.assign(models.createICD(), { location_id: location.location_id });

			esClient.index({ index: 'users', type: 'user', id: user.id, body: Object.assign({ devices: [icd] }, user) })
				.then(() => pubsub.publish(util.getTableName('ICD'), util.EVENTS.REMOVE, icd))
				.then(() => esClient.get({ index: 'users', type: 'user', id: user.id }))
				.then(result => {
					assert.isOk(!result._source.devices || !result._source.devices.length);
					done();
				})
				.catch(done);

		});
	});

});
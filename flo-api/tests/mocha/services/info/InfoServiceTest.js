// const _ = require('lodash');
// const chai = require('chai');
// const chaiAsPromised = require('chai-as-promised');
// const inversify = require('inversify');
// const elasticsearch = require('elasticsearch');
// const config = require('../../../../dist/config/config');
// const describeWithMixins = require('../../utils/describeWithMixins');
// const InfoService = require('../../../../dist/app/services/info/InfoService');
// const UsersIndex = require('../../../../dist/app/services/info/UsersIndex');
// const UsersMappings = require('../../../../dist/app/services/info/models/mappings/users');
// const ICDsIndex = require('../../../../dist/app/services/info/ICDsIndex');
// const ICDsMappings = require('../../../../dist/app/services/info/models/mappings/icds');
// const TICDDoc = require('../../../../dist/app/services/info/models/TICDDoc');
// const TUserDoc = require('../../../../dist/app/services/info/models/TUserDoc');
// const NotFoundException = require('../../../../dist/app/services/utils/exceptions/NotFoundException');
// const ElasticsearchTestMixin = require('../../utils/ElasticsearchTestMixin');

// require('reflect-metadata');

// const elasticsearchTestMixin = new ElasticsearchTestMixin(
// 	{ host: config.elasticSearchHost },
// 	{
// 		users: { mappings: UsersMappings },
// 		icds: { mappings: ICDsMappings }
// 	}
// );

// describeWithMixins('InfoServiceTest', [ elasticsearchTestMixin ], () => {
// 	chai.should();
// 	chai.use(chaiAsPromised);
// 	const container = new inversify.Container();
// 	container.bind(InfoService).to(InfoService);
// 	container.bind(UsersIndex).to(UsersIndex);
// 	container.bind(ICDsIndex).to(ICDsIndex);
// 	container.bind(elasticsearch.Client).toConstantValue(elasticsearchTestMixin.elasticsearchClient);

// 	const elasticsearchClient = container.get(elasticsearch.Client);
// 	const usersIndex = container.get(UsersIndex);
// 	const icdsIndex = container.get(ICDsIndex);
// 	const service = container.get(InfoService);

// 	describe('users', () => {

// 		beforeEach(function (done) {
// 			elasticsearchTestMixin.populateDoctype('users', 'user', TUserDoc)
// 				.then(users => {
// 					this.currentTest.users = users;
// 					done();
// 				})
// 				.catch(done);
// 		});

// 		afterEach(function (done) {
// 			elasticsearchTestMixin.clearDoctype('users', 'user', this.currentTest.users)
// 				.then(() => done())
// 				.catch(done);
// 		});

// 		describe('#retrieveAll', () => {
// 			it('should retrieve all users', function (done) {
// 				service.users.retrieveAll()
// 					.then(({ items }) => items)
// 					.should.eventually.have.deep.members(this.test.users)
// 					.notify(done);
// 			});

// 			it('should filter users based on a criteria', function (done) {
// 				const users = this.test.users.filter(({ is_system_user}) => is_system_user === this.test.users[0].is_system_user);

// 				service.users.retrieveAll({ filter: { is_system_user: this.test.users[0].is_system_user } })
// 					.then(({ items }) => items)
// 					.should.eventually.have.deep.members(users)
// 					.notify(done);
// 			});

// 			it('should only return a page of the specificed size', function (done) {
// 				service.users.retrieveAll({ size: 3 })
// 					.should.eventually
// 						.include({ total: 10 })
// 						.and.have.property('items').with.lengthOf(3)
// 					.notify(done);
// 			});

// 			it('should return sequential pages', function (done) {
// 				const promises = Array(this.test.users.length).fill(null)
// 					.map((emptyData, i) => service.users.retrieveAll({ size: 3, page: i + 1 }));

// 				Promise.all(promises)
// 					.then(results => _.sumBy(results, ({ items }) => items.length))
// 					.should.eventually.equal(this.test.users.length)
// 					.notify(done);
// 			});
// 		});

// 		describe('#retrieveByUserId', () => {
// 			it('should return the user', function (done) {
// 				const user = this.test.users[0];

// 				service.users.retrieveByUserId(user.id)
// 					.should.eventually.deep.equal({
// 						total: 1,
// 						items: [user]
// 					})
// 					.notify(done);
// 			});

// 			it('should throw not found exception', function (done) {
// 				service.users.retrieveByUserId('foo')
// 					.should.eventually.be.rejectedWith(NotFoundException)
// 					.notify(done);
// 			});
// 		});
// 	});

// 	describe('icds', () => {

// 		beforeEach(function (done) {
// 			elasticsearchTestMixin.populateDoctype('icds', 'icd', TICDDoc)
// 				.then(icds => {
// 					this.currentTest.icds = icds;
// 					done();
// 				})
// 				.catch(done);
// 		});

// 		afterEach(function (done) {
// 			elasticsearchTestMixin.clearDoctype('icds', 'icd', this.currentTest.icds)
// 				.then(() => done())
// 				.catch(done);
// 		});

// 		describe('#retrieveAll', () => {
// 			it('should retrieve all icds', function (done) {
// 				service.icds.retrieveAll()
// 					.then(({ items }) => items)
// 					.should.eventually.have.deep.members(this.test.icds)
// 					.notify(done);
// 			});

// 			it('should filter icds based on a criteria', function (done) {
// 				const icds = this.test.icds.filter(({ is_paired}) => is_paired === this.test.icds[0].is_paired);

// 				service.icds.retrieveAll({ filter: { is_paired: this.test.icds[0].is_paired } })
// 					.then(({ items }) => items)
// 					.should.eventually.have.deep.members(icds)
// 					.notify(done);
// 			});

// 			it('should only return a page of the specificed size', function (done) {
// 				service.icds.retrieveAll({ size: 3 })
// 					.should.eventually
// 						.include({ total: 10 })
// 						.and.have.property('items').with.lengthOf(3)
// 					.notify(done);
// 			});

// 			it('should return sequential pages', function (done) {
// 				const promises = Array(this.test.icds.length).fill(null)
// 					.map((emptyData, i) => service.icds.retrieveAll({ size: 3, page: i + 1 }));

// 				Promise.all(promises)
// 					.then(results => _.sumBy(results, ({ items }) => items.length))
// 					.should.eventually.equal(this.test.icds.length)
// 					.notify(done);
// 			});
// 		});

// 		describe('#retrieveByICDId', () => {
// 			it('should return the ICD', function (done) {
// 				const icd = this.test.icds[0];

// 				service.icds.retrieveByICDId(icd.id)
// 					.should.eventually.deep.equal({
// 						total: 1,
// 						items: [icd]
// 					})
// 					.notify(done);
// 			});

// 			it('should throw not found exception', function (done) {
// 				service.icds.retrieveByICDId('foo')
// 					.should.eventually.be.rejectedWith(NotFoundException)
// 					.notify(done);
// 			});
// 		});
// 	});
// });
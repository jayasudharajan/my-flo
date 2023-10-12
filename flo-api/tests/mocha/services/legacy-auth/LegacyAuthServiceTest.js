const _ = require('lodash');
const chai = require('chai');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');
const LegacyAuthService = require('../../../../dist/app/services/legacy-auth/LegacyAuthService');
const InvalidUsernamePasswordException = require('../../../../dist/app/services/authentication/models/exceptions/InvalidUsernamePasswordException');
const InvalidTokenException = require('../../../../dist/app/services/legacy-auth/models/exceptions/InvalidTokenException');

require('reflect-metadata');

chai.use(require('chai-passport-strategy'));

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('LegacyAuthTest', [dynamoDbTestMixin], () => {

  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const userTable = container.get(UserTable);
  const service = container.get(LegacyAuthService);

  beforeEach(function (done) {
    this.currentTest.user = {
      id: randomDataGenerator.generate('UUIDv4'),
      email: randomDataGenerator.generate('Email'),
      password: randomDataGenerator.generate('Password'),
      is_active: true
    };

    userTable.create(this.currentTest.user)
      .then(() => done())
      .catch(done);
  });

  describe('#loginWithUsernamePassword', function () {
  	it('should issue a 24 hour token for a non-mobile client', function (done) {
  		const { email: username, password } = this.test.user;

  		service.loginWithUsernamePassword(username, password, randomDataGenerator.generate('String'), false)
  		  .should.eventually.have.property('tokenExpiration', 24 * 60 * 60)
  		  .notify(done);
  	});

    it('should issue a 30 day token for a mobile client', function (done) {
      const { email: username, password } = this.test.user;

      service.loginWithUsernamePassword(username, password, randomDataGenerator.generate('String'), true)
        .should.eventually.have.property('tokenExpiration', 30 * 24 * 60 * 60)
        .notify(done);
    });

    it('should reject an invalid username and password', function (done) {
      const { email: username } = this.test.user;

      service.loginWithUsernamePassword(username, randomDataGenerator.generate('String'), randomDataGenerator.generate('String'), false)
        .should.eventually.be.rejectedWith(InvalidUsernamePasswordException)
        .notify(done);
    });

  });

  describe('#verifyToken', function () {
    it('should successfully validate the token', function (done) {
      const { id, email: username, password } = this.test.user;

      service.loginWithUsernamePassword(username, password, randomDataGenerator.generate('String'), false)
        .then(({ token }) => service.verifyToken(token))
        .should.eventually.have.property('user_id', id)        
        .notify(done);
    });

    it('should reject an invalid token', function (done) {
      service.verifyToken(randomDataGenerator.generate('String'))
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });
  });

  describe('#getAuthStrategy', function () {
    it('should successfully validate the token', function (done) {
      const { id, email: username, password } = this.test.user;
      const deferred = Promise.defer();

      service.loginWithUsernamePassword(username, password, randomDataGenerator.generate('String'), true)
        .then(({ token }) => {
          chai.passport.use(service.getAuthStrategy())
            .success((user, info) => 
              deferred.resolve({ user, info })
            )
            .error(err => 
              deferred.reject(err)
            )
            .req(req => {
              req.headers.authorization = token;
              req.log = {
                info(msg) { console.log(msg); }
              };
            })
            .authenticate();
        });

        deferred.promise
          .then(({ user, info }) => user.user_id)
          .should.eventually.equal(id)
          .notify(done);
    });

    it('should reject an invalid token', function (done) {
      const deferred = Promise.defer();

      chai.passport.use(service.getAuthStrategy())
        .success((user, info) => 
          deferred.resolve({ user, info })
        )
        .error(err => 
          deferred.reject(err)
        )
        .req(req => {
          req.headers.authorization = randomDataGenerator.generate('String');
          req.log = {
            info(msg) { console.log(msg); }
          };
        })
        .authenticate();

        deferred.promise
          .should.eventually.be.rejectedWith(InvalidTokenException)
          .notify(done);
    });
  });
});
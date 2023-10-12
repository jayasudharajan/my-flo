const _ = require('lodash');
const chai = require('chai');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');
const AuthenticationService = require('../../../../dist/app/services/authentication/AuthenticationService');
const UserLockedException = require('../../../../dist/app/services/authentication/models/exceptions/UserLockedException');
const InvalidUsernamePasswordException = require('../../../../dist/app/services/authentication/models/exceptions/InvalidUsernamePasswordException');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('AuthenticationServiceTest', [ dynamoDbTestMixin ], () => {
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const userTable = container.get(UserTable);
  const service = container.get(AuthenticationService);

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

  describe('#verifyUsernamePassword', function () {
  	it('should succeed with a valid username/password', function (done) {
      const { email: username, password } = this.test.user;

      service.verifyUsernamePassword(username, password)
        .then(userData => _.pick(userData, ['id', 'email']))
      	.should.eventually.deep.equal(
          _.pick(this.test.user, ['id', 'email'])
        )
      	.notify(done);
  	});

    it('should fail with an invalid username/password', function (done) {
      const { email: username } = this.test.user;

      service.verifyUsernamePassword(username, randomDataGenerator.generate('Password'))
        .should.eventually.be.rejectedWith(InvalidUsernamePasswordException)
        .notify(done);
    });

    it('should lock the user after the maximum number of failed login attempts', function (done) {
      const { email: username } = this.test.user;
      
      attemptMultipleLogins(config.maxFailedLoginAttempts + 1, username, randomDataGenerator.generate('Password'))
        .should.eventually.be.rejectedWith(UserLockedException)
        .notify(done);
    });
  });

  describe('#lockUser', function () {
    it('should lock the user', function (done) {
      const { id, email: username, password } = this.test.user;

      service.lockUser(id)
        .then(() => service.verifyUsernamePassword(username, password))
        .should.eventually.be.rejectedWith(UserLockedException)
        .notify(done);
    });
  });

  describe('#unlockUser', function () {
    it('should unlock the user', function (done) {
      const { id, email: username, password } = this.test.user;

      service.lockUser(id)
        .then(() => service.unlockUser(id))
        .then(() => service.verifyUsernamePassword(username, password))
        .should.eventually.be.fulfilled
        .notify(done);
    });

    it('should reset the failed login attempt count', function (done) {
      const { id, email: username, password } = this.test.user;

      attemptMultipleLogins(config.maxFailedLoginAttempts + 1, username, randomDataGenerator.generate('Password'))
        .then(() => Promise.reject(new Error('Should not login.')))
        .catch(err => {
          if (err.name !== UserLockedException.name) {
            return Promise.reject(err);
          } 

          return service.unlockUser(id);
        })
        .then(() => service.verifyUsernamePassword(username, password))
        .should.eventually.be.fulfilled
        .notify(done);
    });
  });

  describe('#isUserLocked', function () {
    it('should return true if the user has been locked', function (done) {
      const { id } = this.test.user;

      service.lockUser(id)
        .then(() => service.isUserLocked(id))
        .should.eventually.equal(true)
        .notify(done);
    });

    it('should return true if the user has been locked then unlocked', function (done) {
      const { id } = this.test.user;

      service.lockUser(id)
        .then(() => service.unlockUser(id))
        .then(() => service.isUserLocked(id))
        .should.eventually.equal(false)
        .notify(done);
    });

    it('should return false if the user has never been locked', function (done) {
      const { id } = this.test.user;

      service.isUserLocked(id)
        .should.eventually.equal(false)
        .notify(done);
    });
  });


function attemptMultipleLogins(number, username, password) {
  return Array(number).fill(null)
    .reduce(
      promise => promise
        .then(() => 
          service.verifyUsernamePassword(username, password)
        )
        .catch(err => {
          if (err.name === InvalidUsernamePasswordException.name) {
            return Promise.resolve();
          } else {
            return Promise.reject(err);
          }
        }),
      Promise.resolve()
    );
  }
});


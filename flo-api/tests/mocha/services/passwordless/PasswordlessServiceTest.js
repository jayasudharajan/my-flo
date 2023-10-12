const _ = require('lodash');
const chai = require('chai');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const AuthenticationService = require('../../../../dist/app/services/authentication/AuthenticationService');
const PasswordlessService = require('../../../../dist/app/services/passwordless/PasswordlessService');
const PasswordlessClientTable = require('../../../../dist/app/services/passwordless/PasswordlessClientTable');
const TPasswordlessClient = require('../../../../dist/app/services/passwordless/models/TPasswordlessClient');
const NotFoundException = require('../../../../dist/app/services/utils/exceptions/NotFoundException');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('PasswordlessServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(PasswordlessService);
  const authenticationService = container.get(AuthenticationService);
  const passwordlessClientTable = container.get(PasswordlessClientTable);
  const userTable = container.get(UserTable);

  beforeEach(function (done) {
    this.currentTest.user = {
      id: randomDataGenerator.generate('UUIDv4'),
      email: randomDataGenerator.generate('Email'),
      password: randomDataGenerator.generate('Password'),
      is_active: true
    };

    this.currentTest.client = {
      client_id: randomDataGenerator.generate('UUIDv4')
    };

    userTable.create(this.currentTest.user)
      .then(() => done())
      .catch(done);
  });

  describe('#sendMagicLink', function () {
    it('should send an email containing the magic link', function (done) {
      const client = this.test.client;
      const user = this.test.user;

      service.sendMagicLink(client, user.email)
        .should.eventually.be.fulfilled
        .notify(done);
    });

    it('should not send an email to an address that does not belong to a user', function (done) {
      const client = this.test.client;

      service.sendMagicLink(client, randomDataGenerator.generate('Email'))
        .should.eventually.be.rejectedWith(NotFoundException)
        .notify(done);
    });
  });

  describe('#redirectWithMagicLink', function () {
    beforeEach(function(done) {
      const passwordlessClient = randomDataGenerator.generate(TPasswordlessClient);

      this.currentTest.passwordlessClient = passwordlessClient;

      passwordlessClientTable.create(passwordlessClient)
        .then(() => done())
        .catch(done);
    });

    it('should redirect to a URI', function (done) {
      const user = this.test.user;
      const passwordlessClient = this.test.passwordlessClient;

      service.redirectWithMagicLink(passwordlessClient.client_id, user.id)
        .should.eventually.be.fulfilled
        .notify(done);
    });

    it('should not redirect with an invalid user ID', function (done) {
      const passwordlessClient = this.test.passwordlessClient;

      service.redirectWithMagicLink(passwordlessClient.client_id, randomDataGenerator.generate('UUIDv4'))
        .should.eventually.be.rejectedWith(NotFoundException)
        .notify(done);
    });
  });

  describe('#loginWithMagicLink', function () {
    it('should return an access and refresh token', function (done) {
        const client = this.test.client;
        const user = this.test.user;

        service.loginWithMagicLink(client, user.id)
          .should.eventually.include.keys(['access_token', 'refresh_token', 'expires_in'])
          .notify(done);
    });

    it('should not return an access and refresh token with an invalid user ID', function (done) {
        const client = this.test.client;

        service.loginWithMagicLink(client, randomDataGenerator.generate('UUIDv4'))
          .should.eventually.be.rejectedWith(NotFoundException)
          .notify(done);
    });

    it('should unlock a locked user', function (done) {
        const client = this.test.client;
        const user = this.test.user;

        authenticationService.lockUser(user.id)
          .then(() => service.loginWithMagicLink(client, user.id))
          .then(() => authenticationService.isUserLocked(user.id))
          .should.eventually.equal(false)
          .notify(done);
    });
  });
}); 
const chai = require('chai');
const UserMultifactorAuthenticationSettingTable = require('../../../../dist/app/services/multifactor-authentication/UserMultifactorAuthenticationSettingTable');
const MultifactorAuthenticationService = require('../../../../dist/app/services/multifactor-authentication/MultifactorAuthenticationService');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');
const MultifactorAuthenticationConfig = require('../../../../dist/app/services/multifactor-authentication/MultifactorAuthenticationConfig');
const TMultifactorAuthenticationMetadata = require('../../../../dist/app/services/multifactor-authentication/models/TMultifactorAuthenticationMetadata');
const InvalidOTPCodeException = require('../../../../dist/app/services/multifactor-authentication/models/exceptions/InvalidOTPCodeException');
const InvalidTokenException = require('../../../../dist/app/services/multifactor-authentication/models/exceptions/InvalidTokenException');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const tcustom = require('../../../../dist/app/models/definitions/CustomTypes');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const config = require('../../../../dist/config/config');
const tableSchemas = require('./resources/tableSchemas');
const validator = require('validator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const ContainerFactory = require('./resources/ContainerFactory');
const uuid = require('node-uuid');
const moment = require('moment');
const speakeasy = require('speakeasy');
require("reflect-metadata");

chai.use(require('chai-passport-strategy'));

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('MultifactorAuthenticationServiceTest', [ dynamoDbTestMixin ], () => {

  const container = new ContainerFactory();
  const randomDataGenerator = new RandomDataGenerator();

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(UserMultifactorAuthenticationSettingTable);
  const service = container.get(MultifactorAuthenticationService);
  const config = container.get(MultifactorAuthenticationConfig);
  const userTable = container.get(UserTable);

  function generateUserMFAConfig(is_enabled) {

    return Object.assign(
      tableTestUtils.generateRecord(table),
      { 
        is_enabled,
        secret: speakeasy.generateSecret().base32
      }
    );
  }

  function generateVerificationCode(base32Secret) {
    return speakeasy.totp({
      secret: base32Secret,
      encoding: 'base32'
    });
  }

  describe('#retrieveUserMFASettings()', function() {
    it('should get MFA metadata for user that is already in the table', function (done) {
      const data = generateUserMFAConfig(0);

      table.create(data).then(() => {
        return service.retrieveUserMFASettings(data.user_id);
      }).then(result => {

        service._getPublicUserMFASettings(data).should.deep.equal(result);

        done();
      }).catch(function (err) {
        done(err);
      });
    });

  });

  describe('#createUserMFASettings()', function() {
    it('should create MFA settings for user', function (done) {
      const userId = randomDataGenerator.generate(tcustom.UUIDv4);


      service.createUserMFASettings(userId).then(result => {
        return Promise.all([
          result,
          table.retrieve(userId)
        ]);
      }).then(([createMetadataResult, { Item: retrieveResult }]) => {

        retrieveResult.should.deep.equal(createMetadataResult);

        done();
      }).catch(function (err) {
        done(err);
      });
    });
  });


  describe('#enableMFA()', function() {

    beforeEach(function (done) {
      const data = generateUserMFAConfig(0);
      const codeToVerify = generateVerificationCode(data.secret);

      table.create(data)
        .then(() => {
          this.currentTest.userId = data.user_id;
          this.currentTest.codeToVerify = codeToVerify;

          done();
        })
        .catch(done);
    });

    it('should enable MFA for user using a valid token', function (done) {
      const { userId, codeToVerify } = this.test;

      service.enableMFA(userId, codeToVerify)
        .then(() => table.retrieve(userId))
        .should.eventually.have.nested.property('Item.is_enabled', 1)
        .notify(done);
    });

    it('should not enable MFA for user due invalid token', function (done) {
      const { userId } = this.test;
      const codeToVerify = '12435566';

      service.enableMFA(userId, codeToVerify)
        .should.eventually.be.rejectedWith(InvalidOTPCodeException)
        .and.notify(done);
    });
  });

  describe('#disableMFA()', function() {

    beforeEach(function (done) {
      const data = generateUserMFAConfig(1);
      const codeToVerify = generateVerificationCode(data.secret);

      table.create(data)
        .then(() => {
          this.currentTest.userId = data.user_id;

          done();
        })
        .catch(done);
    });

    it('should disable MFA for user', function (done) {
      const { userId } = this.test;

      service.disableMFA(userId)
        .then(() => table.retrieve(userId))
        .should.eventually.have.nested.property('Item.is_enabled', 0)
        .notify(done);
    });
  });

  describe('#issueToken', function () {

    it('should issue a token for a user', function (done) {
      const userId = randomDataGenerator.generate('UUIDv4');

      service.issueToken(userId)
        .should.eventually.have.property('token')
        .notify(done);
    });
  });

  describe('#verifyToken', function () {

    it('should successfully verify a valid token', function (done) {
      const userId = randomDataGenerator.generate('UUIDv4');

      service.issueToken(userId)
        .then(({ token }) => service.verifyToken(token))
        .should.eventually.have.property('user_id', userId)
        .notify(done);
    });

    it('should fail to verify an invalid token', function (done) {
      const token = randomDataGenerator.generate('String');

      service.verifyToken(token)
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });

    it('should only allow the token to be used once', function (done) {
      const userId = randomDataGenerator.generate('UUIDv4');

      service.issueToken(userId)
        .then(({ token }) => 
          service.verifyToken(token)
            .then(() => service.verifyToken(token))
        )
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });
  });

  describe('#isMFAEnabled', function (done) {

    beforeEach(function (done) {
      const data = generateUserMFAConfig(0);
      const codeToVerify = generateVerificationCode(data.secret);

      table.create(data)
        .then(() => {
          this.currentTest.userId = data.user_id;
          this.currentTest.codeToVerify = codeToVerify;

          done();
        })
        .catch(done);
    });

    it('should return false if MFA has never been enabled for the user', function (done) {
      const userId = randomDataGenerator.generate('UUIDv4');

      service.isMFAEnabled(userId)
        .should.eventually.equal(false)
        .notify(done);
    });

    it('should return true if MFA is enabled for the user', function (done) {
      const { userId, codeToVerify } = this.test;

      service.enableMFA(userId, codeToVerify)
        .then(() => service.isMFAEnabled(userId))
        .should.eventually.equal(true)
        .notify(done);
    });

    it('should return false if MFA has been disabled for the user', function (done) {
      const { userId, codeToVerify } = this.test;

      service.enableMFA(userId, codeToVerify)
        .then(() => service.disableMFA(userId))
        .then(() => service.isMFAEnabled(userId))
        .should.eventually.equal(false)
        .notify(done);
    });

  });

  describe('#getAuthStrategy', function () {

    beforeEach(function (done) {
      const data = generateUserMFAConfig(1);
      const codeToVerify = generateVerificationCode(data.secret);
      const clientId = randomDataGenerator.generate('UUIDv4');

      Promise.all([
        service.issueToken(data.user_id, { client_id: clientId }),
        table.create(data)
      ])
      .then(([{ token }]) => {
        this.currentTest.userId = data.user_id;
        this.currentTest.verificationCode = codeToVerify;
        this.currentTest.clientId = clientId;
        this.currentTest.mfaToken = token;

        done();
      })
      .catch(done);
    });

    it('should successfully authenticate a valid MFA code and token', function (done) {
      const deferred = Promise.defer();

      chai.passport.use(service.getAuthStrategy())
        .success(user => deferred.resolve(user))
        .fail(err => deferred.resolve(false))
        .error(err => deferred.reject(err))
        .req(req => {
          req.body = {
            mfa_token: this.test.mfaToken,
            code: this.test.verificationCode
          };
        })
        .authenticate();

      deferred.promise
        .should.eventually.deep.equal({
          user_id: this.test.userId,
          client_id: this.test.clientId
        })
        .notify(done);
    });

    it('should fail to authenticate a valid MFA token and invalid MFA code', function (done) {
      const deferred = Promise.defer();

      chai.passport.use(service.getAuthStrategy())
        .success(user => deferred.resolve(user))
        .fail(err => deferred.resolve(false))
        .error(err => deferred.reject(err))
        .req(req => {
          req.body = {
            mfa_token: this.test.mfaToken,
            code: randomDataGenerator.generate('String')
          };
        })
        .authenticate();

      deferred.promise
        .should.eventually.equal(false)
        .notify(done);
    });

    it('should fail to authenticate a invalid MFA token and valid MFA code', function (done) {
      const deferred = Promise.defer();

      chai.passport.use(service.getAuthStrategy())
        .success(user => deferred.resolve(user))
        .fail(err => deferred.resolve(false))
        .error(err => deferred.reject(err))
        .req(req => {
          req.body = {
            mfa_token: randomDataGenerator.generate('String'),
            code: this.test.verificationCode
          };
        })
        .authenticate();

      deferred.promise
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });  
  });
});
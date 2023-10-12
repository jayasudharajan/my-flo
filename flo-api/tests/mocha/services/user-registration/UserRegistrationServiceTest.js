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
const TUserRegistrationData = require('../../../../dist/app/services/user-registration/models/TUserRegistrationData');
const TRegistrationFlow = require('../../../../dist/app/services/user-registration/models/TRegistrationFlow');
const UserRegistrationService = require('../../../../dist/app/services/user-registration/UserRegistrationService');
const InvalidSessionException = require('../../../../dist/app/services/user-registration/models/exceptions/InvalidSessionException');
const SessionTerminatedException = require('../../../../dist/app/services/user-registration/models/exceptions/SessionTerminatedException');
const PasswordsMismatchException = require('../../../../dist/app/services/user-registration/models/exceptions/PasswordsMismatchException');
const EmailAlreadyInUseException = require('../../../../dist/app/services/user-account/models/exceptions/EmailAlreadyInUseException');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');
const LocationService = require('../../../../dist/app/services/location-v1_5/LocationService');
const UserAccountService = require('../../../../dist/app/services/user-account/UserAccountService');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('UserRegistrationServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(UserRegistrationService);
  const locationService = container.get(LocationService);
  const userTable = container.get(UserTable);
  const userAccountService = container.get(UserAccountService);
  const optionsNoMaybes = {maybeDeleted: true}

  describe('#checkEmailAvailability', function () {
    it('should indicate the email has been registered', function (done) {
      const id = randomDataGenerator.generate('UUIDv4');
      const email = randomDataGenerator.generate('Email');
      const password = randomDataGenerator.generate('Password');

      userTable.create({ id, email, password })
        .then(() => service.checkEmailAvailability(email))
        .should.eventually.deep.equal({ is_registered: true, is_pending: false })
        .notify(done);
    });

    it('should indicate the email is available', function (done) {
      const email = randomDataGenerator.generate('Email');

      service.checkEmailAvailability(email)
        .should.eventually.deep.equal({ is_registered: false, is_pending: false })
        .notify(done);
    });
  });

  describe('#acceptTermsAndSendVerificationEmail', function () {
    it('should send an email with a registration token', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const registrationData =  Object.assign(
        {}, 
        data, 
        { password_conf: data.password }
      );

      service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress)
        .should.eventually.include.key('token')
        .notify(done);
    });

    it('should not send an email if the passwords do not match', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);

      service.acceptTermsAndSendVerificationEmail(data, flowType, ipAddress)
      .should.eventually.be.rejected
      .notify(done);
    });

    it('should not send an email if there is already a pending registration', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const registrationData =  Object.assign(
        {}, 
        data, 
        { password_conf: data.password }
      );
      service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress)
        .then(() => service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress))
        .should.eventually.be.rejectedWith(InvalidSessionException)
        .notify(done);
    });
  });

  describe('#verifyEmailAndCreateUser', function () {
    it('should create a user from a valid registration token', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);

      service.acceptTermsAndSendVerificationEmail(
        Object.assign(
          {}, 
          data, 
          { password_conf: data.password }
        ), 
        flowType,
        ipAddress
      )
      .then(({ token }) => service.verifyEmailAndCreateUser(token))
      .then(({ user_id }) => userTable.retrieve({ id: user_id }))
      .then(({ Item }) => Item)
      .should.eventually.deep.include({ is_active: true })
      .notify(done);
    });


    it('should create a user from a valid registration token with a hashed password', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const hash = randomDataGenerator.generate('HashedPassword');
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);

      service.acceptTermsAndSendVerificationEmail(
        Object.assign(
          {}, 
          data, 
          { 
            password: hash,
            passwordHash: true,
            password_conf: hash,
          }
        ), 
        flowType,
        ipAddress
      )
      .then(({ token }) => service.verifyEmailAndCreateUser(token))
      .then(({ user_id }) => userTable.retrieve({ id: user_id }))
      .then(({ Item }) => Item)
      .should.eventually.deep.include({ is_active: true })
      .notify(done);
    });

    it('should not create a user if the email already exists', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);

      Promise.all([
        service.acceptTermsAndSendVerificationEmail(
          Object.assign(
            {}, 
            data, 
            { password_conf: data.password }
          ), 
          flowType,
          ipAddress
        ),
        userTable.create(
          Object.assign(
            { id: randomDataGenerator.generate('UUIDv4') },
            _.pick(data, ['email', 'password'])
          )
        )
      ])
      .then(([{ token }]) => service.verifyEmailAndCreateUser(token))
      .should.eventually.be.rejectedWith(EmailAlreadyInUseException)
      .notify(done);
    });

  });

  describe('#loginUserWithLegacyAuth', function () {
    it('should login the user with a valid registration token', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const userAgent = randomDataGenerator.generate('String');
      const registrationData =  Object.assign(
        {}, 
        data, 
        { password_conf: data.password }
      );

      service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress)
        .then(({ token }) => 
          service.verifyEmailAndCreateUser(token)
            .then(() => token)
        )
        .then(token => service.loginUserWithLegacyAuth(token, userAgent))
        .should.eventually.include.property('token')
        .notify(done);
    });

    it('should not login the user more than once with the same token', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const userAgent = randomDataGenerator.generate('String');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);

      service.acceptTermsAndSendVerificationEmail(
        Object.assign(
          {}, 
          data, 
          { password_conf: data.password }
        ), 
        flowType,
        ipAddress
      )
      .then(({ token }) => 
        service.verifyEmailAndCreateUser(token)
          .then(() => token)
      )
      .then(token => 
        service.loginUserWithLegacyAuth(token, userAgent)
          .then(() => service.loginUserWithLegacyAuth(token, userAgent))
      )
      .should.eventually.be.rejectedWith(InvalidSessionException)
      .notify(done);      
    });
  });

  describe('#loginUserWithOAuth2', function () {
    it('should login the user with a valid registration token', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const client = { client_id: randomDataGenerator.generate('UUIDv4') };
      const registrationData =  Object.assign(
        {}, 
        data, 
        { password_conf: data.password }
      );

      service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress)
        .then(({ token }) => 
          service.verifyEmailAndCreateUser(token)
            .then(() => token)
        )
        .then(token => service.loginUserWithOAuth2(token, client))
        .should.eventually.include.property('access_token')
        .notify(done);
    });

    it('should not login the user more than once with the same token', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const client = { client_id: randomDataGenerator.generate('UUIDv4') };

      service.acceptTermsAndSendVerificationEmail(
        Object.assign(
          {}, 
          data, 
          { password_conf: data.password }
        ), 
        flowType,
        ipAddress
      )
      .then(({ token }) => 
        service.verifyEmailAndCreateUser(token)
          .then(() => token)
      )
      .then(token => 
        service.loginUserWithOAuth2(token, client)
          .then(() => service.loginUserWithOAuth2(token, client))
      )
      .should.eventually.be.rejectedWith(InvalidSessionException)
      .notify(done);      
    });
  });

  describe('#resendVerificationEmail', function () {
    it('should resend the verification email', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const registrationData =  Object.assign(
        {}, 
        data, 
        { password_conf: data.password }
      );

      service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress)
        .then(() => service.resendVerificationEmail(data.email))
        .should.eventually.include.key('token')
        .notify(done);
    });

    it('should create and login the user from the resent email', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const userAgent = randomDataGenerator.generate('String');
      const registrationData =  Object.assign(
        {}, 
        data, 
        { password_conf: data.password }
      );

      service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress)
        .then(() => service.resendVerificationEmail(data.email))
        .then(({ token }) => 
          service.verifyEmailAndCreateUser(token)
            .then(() => token)
        )
        .then(token => service.loginUserWithLegacyAuth(token, userAgent))
        .should.eventually.include.property('token')
        .notify(done);      
    });

    it('should create and login the user from the original email', function (done) {
      const data = randomDataGenerator.generate(TUserRegistrationData, optionsNoMaybes);
      const ipAddress = randomDataGenerator.generate('IPAddress');
      const flowType = randomDataGenerator.generate(TRegistrationFlow);
      const userAgent = randomDataGenerator.generate('String');
      const registrationData =  Object.assign(
        {}, 
        data, 
        { password_conf: data.password }
      );

      service.acceptTermsAndSendVerificationEmail(registrationData, flowType, ipAddress)
        .then(({ token }) => 
          service.resendVerificationEmail(data.email)
            .then(() => token)
        )
        .then(token => 
          service.verifyEmailAndCreateUser(token)
            .then(() => token)
        )
        .then(token => service.loginUserWithLegacyAuth(token, userAgent))
        .should.eventually.include.property('token')
        .notify(done);      
    });
  });
});
const _ = require('lodash');
const chai = require('chai');
const TUserData = require('../../../../dist/app/services/user-account/models/TUserData');
const EmailAlreadyInUseException = require('../../../../dist/app/services/user-account/models/exceptions/EmailAlreadyInUseException');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const NotFoundException = require('../../../../dist/app/services/utils/exceptions/NotFoundException');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const UserAccountService = require('../../../../dist/app/services/user-account/UserAccountService');
const UserAccountRoleTable = require('../../../../dist/app/services/authorization/UserAccountRoleTable');
const UserLocationRoleTable = require('../../../../dist/app/services/authorization/UserLocationRoleTable');


require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('UserAccountServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const service = container.get(UserAccountService);
  const userLocationRoleTable = container.get(UserLocationRoleTable);
  const userAccountRoleTable = container.get(UserAccountRoleTable);

  describe('#createNewUserAndAccount', function () {
    it('should create a new user and a new account with that user as its owner', function (done) {
      const userData = randomDataGenerator.generate(TUserData, { maybeDeleted: true });

      service.createNewUserAndAccount(userData)
        .then(({ user_id, account_id, location_id }) => 
          Promise.all([
            service.userTable.retrieve({ id: user_id }),
            service.userDetailTable.retrieve({ user_id }),
            service.accountService.retrieve({ id: account_id }),
            service.locationService.retrieve({ account_id, location_id }),
            userAccountRoleTable.retrieve({ user_id, account_id }),
            userLocationRoleTable.retrieve({ user_id, location_id })
          ])    
          .then(([
            { Item: user }, 
            { Item: userDetail }, 
            { Item: account }, 
            { Item: location }, 
            { Item: userAccountRole }, 
            { Item: userLocationRole }
          ]) => Object.assign(
            _.pick(user, ['email', 'is_active']),
            _.chain(userDetail).omit(['user_id']).omitBy(_.isNil).value(),
            _.pick(account, ['owner_user_id']),
            _.pick(location, _.chain(userData).omitBy(_.isNil).keys().value()),            
            { account_roles: userAccountRole.roles },
            { location_roles: userLocationRole.roles }
          ))
          .should.eventually.deep.equal(Object.assign(
            _.chain(userData).omitBy(_.isNil).omit(['password']).value(),
            { 
              locale: 'en-us',
              owner_user_id: user_id,
              is_active: false,
              account_roles: ['owner'],
              location_roles: ['owner'] 
            }
          ))
          .notify(done)
        )
        .catch(done);
    });

    it('should not allow creating an account with a duplicate email', function (done) {
      const userData1 = randomDataGenerator.generate(TUserData, { maybeDeleted: true });
      const userData2 = Object.assign(
        randomDataGenerator.generate(TUserData, { maybeDeleted: true }),
        { email: userData1.email }
      );

      service.createNewUserAndAccount(userData1)
        .then(() => service.createNewUserAndAccount(userData2))
        .should.be.rejectedWith(EmailAlreadyInUseException)
        .notify(done);
    });
  });

  describe('#removeUserAndAccount', function () {
    it('should remove the entire user', function (done) {
      const userData = randomDataGenerator.generate(TUserData, { maybeDeleted: true });

      service.createNewUserAndAccount(userData)
        .then(({ user_id, account_id, location_id }) => 
          service.removeUserAndAccount(user_id, account_id, location_id)
            .then(() => ({ user_id, account_id, location_id })) 
        )
        .then(({ user_id, account_id, location_id }) => 
          Promise.all([
            service.userTable.retrieve({ id: user_id }),
            service.userDetailTable.retrieve({ user_id }),
            service.accountService.accountTable.retrieve({ id: account_id }),
            service.locationService.locationTable.retrieve({ account_id, location_id }),
            userAccountRoleTable.retrieve({ user_id, account_id }),
            userLocationRoleTable.retrieve({ user_id, location_id })
          ])
        )    
        .then(([
          { Item: user }, 
          { Item: userDetail }, 
          { Item: account }, 
          { Item: location }, 
          { Item: userAccountRole }, 
          { Item: userLocationRole }
        ]) => (
          [
            user,
            userDetail,
            account,
            location,
            userAccountRole,
            userLocationRole
          ].filter(entity => entity && !_.isEmpty(entity))
        ))
        .should.eventually.be.empty
        .notify(done);
    });
  });
});
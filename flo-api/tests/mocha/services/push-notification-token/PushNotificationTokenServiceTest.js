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
const PushNotificationTokenService = require('../../../../dist/app/services/push-notification-token/PushNotificationTokenService');
const PushNotificationTokenTable = require('../../../../dist/app/services/push-notification-token/PushNotificationTokenTable');
const TPushNotificationToken = require('../../../../dist/app/services/push-notification-token/models/TPushNotificationToken');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('PushNotificationTokenServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(PushNotificationTokenService);
  const table = container.get(PushNotificationTokenTable);

  describe('#create', function () {
    it('should replace a user_id for the same mobile device and client', function (done) {
      const data = randomDataGenerator.generate(TPushNotificationToken, { maybeDeleted: true });
      const userId1 = randomDataGenerator.generate('UUIDv4');
      const userId2 = randomDataGenerator.generate('UUIDv4');

      service.create(Object.assign({}, data, { user_id: userId1 }))
        .then(() => service.create(Object.assign({}, data, { user_id: userId2 })))
        .then(() => table.retrieve(_.pick(data, ['mobile_device_id', 'client_id'])))
        .should.eventually.have.property('Item').that.contains(Object.assign({}, data, { user_id: userId2 }))
        .notify(done);
    });
  });

  describe('#retrieveByUserId', function () {
    it('should retrieve all records with user id', function (done) {
      const data1 = randomDataGenerator.generate(TPushNotificationToken, { maybeDeleted: true });
      const data2 = Object.assign(
        randomDataGenerator.generate(TPushNotificationToken, { maybeDeleted: true }),
        _.pick(data1, ['user_id'])
      );

      Promise.all([service.create(data1), service.create(data2)])
        .then(() => service.retrieveByUserId(data1.user_id))
        .then(results => results.map(result => _.omit(result, ['created_at', 'updated_at'])))
        .should.eventually.deep.contain.members([data1, data2])
        .notify(done);
    });
  });
}); 
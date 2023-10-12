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
const AccountGroupAlarmNotificationDeliveryRuleService = require('../../../../dist/app/services/account-group-alarm-notification-delivery-rule/AccountGroupAlarmNotificationDeliveryRuleService');
const AccountGroupAlarmNotificationDeliveryRuleTable = require('../../../../dist/app/services/account-group-alarm-notification-delivery-rule/AccountGroupAlarmNotificationDeliveryRuleTable');
const TAccountGroupAlarmNotificationDeliveryRule = require('../../../../dist/app/services/account-group-alarm-notification-delivery-rule/models/TAccountGroupAlarmNotificationDeliveryRule');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('AccountGroupAlarmNotificationDeliveryRuleServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(AccountGroupAlarmNotificationDeliveryRuleService);
  const table = container.get(AccountGroupAlarmNotificationDeliveryRuleTable);

  function generateCompoundKey(data) {
    return `${ data.alarm_id }_${ data.system_mode }_${ data.user_role }`;
  }

  describe('#create', function () {
    it('should create a new record', function (done) {
      const data = randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule);

      service.create(data)
        .then(() => table.retrieve({
          group_id: data.group_id, 
          alarm_id_system_mode_user_role: generateCompoundKey(data)
        }))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(data)
        .notify(done);
    });
  });

  describe('#retrieve', function () {
    it('should retrieve a record', function (done) {
      const data = randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule);

      table.create(data)
        .then(() => service.retrieve(data.group_id, generateCompoundKey(data)))
        .should.eventually.deep.equal(data)
        .notify(done);
    });

    it('should return an empty result if no record is found', function (done) {

      service.retrieve(randomDataGenerator.generate('UUIDv4'), randomDataGenerator.generate('String'))
        .should.eventually.be.empty
        .notify(done);
    });
  });

  describe('#update', function () {
    it('should update an existing record', function (done) {
      const data = randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule);
      const updatedData = Object.assign(
        {},
        data,
        _.omit(randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule), ['group_id', 'alarm_id', 'system_mode', 'user_role'])
      );

      table.create(data)
        .then(() => service.update(updatedData))
        .then(() => table.retrieve({
          group_id: data.group_id, 
          alarm_id_system_mode_user_role: generateCompoundKey(data)
        }))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(updatedData)
        .notify(done);
    });

    it('should fail to update a non-existant record', function (done) {
      const data = randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule);

      service.update(data)
        .should.eventually.be.rejected
        .notify(done);
    }); 
  });

  describe('#patch', function () {
    it('should partially update a record', function (done) {
      const data = randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule);
      const updatedData = _.omit(randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule), ['group_id', 'alarm_id', 'system_mode', 'user_role']);

      table.create(data)
        .then(() => 
          service.patch(
            { 
              group_id: data.group_id, 
              alarm_id_system_mode_user_role: generateCompoundKey(data) 
            },
            updatedData
          )
        )
        .then(() => table.retrieve({
          group_id: data.group_id,
          alarm_id_system_mode_user_role: generateCompoundKey(data)
        }))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(Object.assign({}, data, updatedData))
        .notify(done);
    });
  });

  describe('#remove', function () {
    it('should remove a record', function (done) {
      const data = randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule);

      table.create(data)
        .then(() => service.remove(data.group_id, generateCompoundKey(data)))
        .then(() => table.retrieve({
          group_id: data.group_id, 
          alarm_id_system_mode_user_role: generateCompoundKey(data)
        }))
        .then(({ Item }) => Item)
        .should.eventually.not.exist
        .notify(done);
    });

    it('should not error if the record does not exist', function (done) {

      service.remove(randomDataGenerator.generate('UUIDv4'), randomDataGenerator.generate('String'))
        .should.eventually.be.fulfilled
        .notify(done);
    });
  });

  describe('#retrieveByGroupIdAlarmIdSystemMode', function () {
    it('should retrieve a record', function (done) {
      const data = randomDataGenerator.generate(TAccountGroupAlarmNotificationDeliveryRule);

      table.create(data)
        .then(() => service.retrieveByGroupIdAlarmIdSystemMode(data.group_id, data.alarm_id, data.system_mode))
        .should.eventually.deep.equal([data])
        .notify(done);
    });
  });
}); 
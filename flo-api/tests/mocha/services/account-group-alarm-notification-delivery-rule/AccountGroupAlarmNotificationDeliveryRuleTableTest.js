const chai = require('chai');
const AWS = require('aws-sdk');
const tableSchemas = require('./resources/tableSchemas');
const ContainerFactory = require('./resources/ContainerFactory');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const AccountGroupAlarmNotificationDeliveryRuleTable = require('../../../../dist/app/services/account-group-alarm-notification-delivery-rule/AccountGroupAlarmNotificationDeliveryRuleTable');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('AccountGroupAlarmNotificationDeliveryRuleTableTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const table = container.get(AccountGroupAlarmNotificationDeliveryRuleTable);

  tableTestUtils.crudTableTests(table, {
    getRetrieveParamsValues: (table, record) => {
      return {
        group_id: record.group_id,
        alarm_id_system_mode_user_role: `${ record.alarm_id }_${ record.system_mode }_${ record.user_role }`
      };
    },
    getUpdatedRecord: (table, record, options) => {
      return Object.assign(
        tableTestUtils.getUpdatedRecord(table, record, options),
        {
          alarm_id: record.alarm_id,
          system_mode: record.system_mode,
          user_role: record.user_role
        }
      );
    }
  });

  describe('#retrieveByGroupId', function () {
    it('should return records by group ID', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => table.retrieveByGroupId(record.group_id))
        .then(({ Items }) => Items)
        .should.eventually.deep.equal([record])
        .notify(done);
    });
  });

  describe('#retrieveByGroupIdAlarmIdSystemMode', function () {
    it('should return records by group, alarm ID, and system mode', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(() => table.retrieveByGroupIdAlarmIdSystemMode(record.group_id, record.alarm_id, record.system_mode))
        .then(({ Items }) => Items)
        .should.eventually.deep.equal([record])
        .notify(done);
    });
  });
});
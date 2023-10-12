const _ = require('lodash');
const chai = require('chai');
const AWS = require('aws-sdk');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const AlertFeedbackService = require('../../../../dist/app/services/alert-feedback/AlertFeedbackService');
const AlertFeedbackTable = require('../../../../dist/app/services/alert-feedback/AlertFeedbackTable');
const AlertFeedbackFlowTable = require('../../../../dist/app/services/alert-feedback/AlertFeedbackFlowTable');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const tableTestUtils = require('../../utils/tableTestUtils');
const TAlertFeedback = require('../../../../dist/app/services/alert-feedback/models/TAlertFeedback');
const TAlertFeedbackFlow = require('../../../../dist/app/services/alert-feedback/models/TAlertFeedbackFlow');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('AlertFeedbackServiceTest', [ dynamoDbTestMixin ], function() {
  const container = ContainerFactory();
  const randomDataGenerator = new RandomDataGenerator();

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(AlertFeedbackService);
  const alertFeedbackTable = container.get(AlertFeedbackTable);
  const alertFeedbackFlowTable = container.get(AlertFeedbackFlowTable);

  describe('#submitFeedback', function() {
    it('should insert feedback', function(done) {
      const alertFeedback = randomDataGenerator.generate(TAlertFeedback, { maybeDeleted: true });

      service.submitFeedback(alertFeedback)
        .then(() => alertFeedbackTable.retrieve(alertFeedback.icd_id, alertFeedback.incident_id))
        .then(({ Item }) => Item)
        .should.eventually.include(alertFeedback)
        .notify(done);
    });
  });

  describe('#retrieveFeedback', function() {
    it('should retrieve feedback', function (done) {
      const alertFeedback = randomDataGenerator.generate(TAlertFeedback, { maybeDeleted: true });

      alertFeedbackTable.create(alertFeedback)
        .then(() => service.retrieveFeedback(alertFeedback.icd_id, alertFeedback.incident_id))
        .should.eventually.include(alertFeedback)
        .notify(done);
    });
  });

  describe('#retrieveFlow', function() {
    it('should retrieve the feedback flow', function(done) {
      const alertFeedbackFlow = randomDataGenerator.generate(TAlertFeedbackFlow, { maybeDeleted: true });

      alertFeedbackFlowTable.create(alertFeedbackFlow)
        .then(() => service.retrieveFlow(alertFeedbackFlow.alarm_id, alertFeedbackFlow.system_mode))
        .should.eventually.deep.equal(alertFeedbackFlow)
        .notify(done);
    });
  });

});
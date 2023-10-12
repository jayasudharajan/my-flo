const chai = require('chai');
const MicroLeakTestTimeTable = require('../../../../dist/app/services/microleak-test-time/MicroLeakTestTimeTable');
const MicroLeakTestTimeService = require('../../../../dist/app/services/microleak-test-time/MicroLeakTestTimeService');
const DirectiveConfig = require('../../../../dist/app/services/directives/DirectiveConfig');
const DirectiveLogTable = require('../../../../dist/app/models/DirectiveLogTable');
const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
const KafkaProducer = require('../../../../dist/app/services/utils/KafkaProducer');
const KafkaProducerMock = require('../../utils/KafkaProducerMock');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const config = require('../../../../dist/config/config');
const tableSchemas = require('./resources/tableSchemas');
const qr = require('../../../../dist/util/qrCodeUtil');
const validator = require('validator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const ContainerFactory = require('./resources/ContainerFactory');
const uuid = require('node-uuid');
const _ = require('lodash');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('MicroLeakTestTimeServiceTest', [ dynamoDbTestMixin ], () => {

  const kafkaProducer = new KafkaProducerMock();
  const container = new ContainerFactory(kafkaProducer);

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const icdTable = container.get(ICDTable);
  const directiveLogTable = container.get(DirectiveLogTable);
  const microLeakTestTimeTable = container.get(MicroLeakTestTimeTable);
  const service = container.get(MicroLeakTestTimeService);
  const config = container.get(DirectiveConfig);

  describe('#deployTimesConfig()', function() {
    it('should send stock icd request to kafka', function(done) {
      const icd = tableTestUtils.generateRecord(icdTable);
      const userId = uuid.v4();
      //3AM (180), then 220 (3:40am) then 150 (2:30am)
      const times = [ 180, 220, 150 ];

      icdTable.create(icd).then(() => {
        return service.deployTimesConfig(
          icd.device_id,
          {
            times,
            compute_time: '2018-06-05T02:00:08+00:00',
            reference_time: {
              timezone: 'some/timezone',
              data_start_date: '2018-06-05T02:00:08+00:00'
            }
          },
          userId,
          'appUsed'
        );
      }).then(() => {
        return Promise.all([
          config.getDirectivesKafkaTopic(),
          directiveLogTable.retrieveByICDId({ icd_id: icd.id }),
          microLeakTestTimeTable.retrieveLatest({ device_id: icd.device_id })
        ]);
      }).then(([ directivesTopic, directiveLogResult , microLeakTestTimeResult ]) => {
        const message = kafkaProducer.getSentMessages(directivesTopic)[0];

        message.icd_id.should.equal(icd.id);
        message.state.should.equal(1);
        message.directive.device_id.should.equal(icd.device_id);
        message.directive.directive.should.equal('update-health-test-config-v2');
        message.directive.data.configs.length.should.equal(times.length);

        directiveLogResult.Items.length.should.equal(1);
        microLeakTestTimeResult.Items.length.should.equal(1);

        const mlttRecord = microLeakTestTimeResult.Items[0];

        mlttRecord.device_id.should.equal(icd.device_id);
        mlttRecord.created_at_device_id.should.equal(mlttRecord.created_at + '_' + icd.device_id);
        mlttRecord.times.length.should.equal(times.length);
        mlttRecord.is_deployed.should.equal(0);

        done();

        return message;
      }).catch(function (err) {
        done(err);
      });
    });
  });

  describe('#retrievePendingTimesConfig()', function() {
    it('should retrieve items with isDeployed eq to "0"', function(done) {


      const isDeployedArray = _.range(0, 10).map(index => _.random(0, 1))
      const microLeakTestTimeRecords = isDeployedArray.map(isDeployed =>
        (_.assign(tableTestUtils.generateRecord(microLeakTestTimeTable), { is_deployed: isDeployed })));
      Promise.all(microLeakTestTimeRecords.map(record => microLeakTestTimeTable.create(record)))
        .then(() => {
          return service.retrievePendingTimesConfig();
        })
        .then(records => {
          const totalDeployed = isDeployedArray.filter(isDeployed => isDeployed == 0)
          records.data.length.should.equal(totalDeployed.length);
          done()
        })
        .catch((err) => {
          done(err);
        });


    });
  });
});
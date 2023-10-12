const chai = require('chai');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const MicroLeakTestTimeTable = require('../../../../dist/app/services/microleak-test-time/MicroLeakTestTimeTable');
const DirectiveConfig = require('../../../../dist/app/services/directives/DirectiveConfig');
const DirectiveLogTable = require('../../../../dist/app/models/DirectiveLogTable');
const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
const LocationTable = require('../../../../dist/app/services/location-v1_5/LocationTable');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const AppServerTestMixin = require('../../utils/AppServerTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const AppServerFactory = require('../../../../dist/AppServerFactory');
const AppServerTestUtils = require('../../utils/AppServerTestUtils');
const KafkaProducerMock = require('../../utils/KafkaProducerMock');
const tableSchemas = require('./resources/tableSchemas');
const ContainerFactory = require('./resources/ContainerFactory');
const uuid = require('node-uuid');
const _ = require('lodash');
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const kafkaProducer = new KafkaProducerMock();
const container = new ContainerFactory(kafkaProducer);

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

const appServerFactory = new AppServerFactory(AppServerTestUtils.withRandomPort(config), container);
const appServerTestMixin = new AppServerTestMixin(appServerFactory);

/*
describeWithMixins('MicroLeakTestTimeHttpTest', [ dynamoDbTestMixin, appServerTestMixin ], () => {

  const endpoint = 'api/v1/microleaktesttime/deploy/configs/:device_id';

  // Resolve dependencies
  const icdTable = container.get(ICDTable);
  const locationTable = container.get(LocationTable);
  const directiveLogTable = container.get(DirectiveLogTable);
  const microLeakTestTimeTable = container.get(MicroLeakTestTimeTable);
  const config = container.get(DirectiveConfig);

  describe('POST ' + endpoint, function() {
    it('should send new microleak test times to the icd and save the config in a table', function (done) {
      const icd = tableTestUtils.generateRecord(icdTable);
      const location = tableTestUtils.generateRecord(locationTable);
      const userId = uuid.v4();
      //3AM (180), then 220 (3:40am) then 150 (2:30am)
      const times = [ 180, 220, 150 ];

      icd.location_id = location.location_id;

      Promise.all([
        icdTable.create(icd),
        locationTable.create(location)
      ]).then(result => {

        console.log("######## LOG1");

        console.log(endpoint.replace(':device_id', icd.device_id));

        return chai.request(appServerFactory.instance())
          .post(endpoint.replace(':device_id', icd.device_id))
          .send({ times });
      }).then(httpResponse => {

        console.log("#########ALOOO");

        return Promise.all([
          config.getDirectivesKafkaTopic(),
          httpResponse,
          directiveLogTable.retrieveByICDId(icd.id),
          microLeakTestTimeTable.retrieveLatest({ device_id: icd.device_id })
        ]);
      }).then(([ directivesTopic, httpResponse, directiveLogResult , microLeakTestTimeResult ]) => {
        const message = kafkaProducer.getSentMessages(directivesTopic)[0];

        httpResponse.should.deep.include({ status: 200 });

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
});
*/


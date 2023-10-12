const _ = require('lodash');
const chai = require('chai');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const AppServerTestMixin = require('../../utils/AppServerTestMixin');
const AppServerFactory = require('../../../../dist/AppServerFactory');
const AppServerTestUtils = require('../../utils/AppServerTestUtils');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const OnboardingService = require('../../../../dist/app/services/onboarding/OnboardingService');
const requestTypes = require('../../../../dist/app/services/onboarding/models/requestTypes');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');

require('reflect-metadata');

/*
const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

// Declare bindings
const container = ContainerFactory();
container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

const appServerFactory = new AppServerFactory(AppServerTestUtils.withRandomPort(config), container);
const appServerTestMixin = new AppServerTestMixin(appServerFactory);


describeWithMixins('OnboardingHttpTest', [ dynamoDbTestMixin, appServerTestMixin ], () => {
  const baseEndpoint = '/api/v1/onboarding/';
  const onDeviceInstalledEndpoint = 'event/device/installed';
  const randomDataGenerator = new RandomDataGenerator();


  describe('POST ' + onDeviceInstalledEndpoint, function() {
    it('should send installation email and schedule emails for 3 and 21 days after installation', function (done) {
      const data = randomDataGenerator.generate(requestTypes.doOnDeviceInstalled.body);

      console.log(data);

      console.log(appServerFactory.instance());

      chai.request(appServerFactory.instance())
        .post(onDeviceInstalledEndpoint)
        .send(data)
        .should.eventually.deep.include({ status: 200, body: data}).notify(done);
    });
  });
});
*/
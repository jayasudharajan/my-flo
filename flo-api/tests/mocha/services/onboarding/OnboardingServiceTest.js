const _ = require('lodash');
const chai = require('chai');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const OnboardingService = require('../../../../dist/app/services/onboarding/OnboardingService');
const TOnboardingEvent = require('../../../../dist/app/services/onboarding/models/TOnboardingEvent');
const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const tableTestUtils = require('../../utils/tableTestUtils');
const KafkaProducerMock = require('../../utils/KafkaProducerMock');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('OnboardingServiceTest', [ dynamoDbTestMixin ], () => {

  const kafkaProducerMock = new KafkaProducerMock();
  const configMock = {
    eventsAckTopic: 'events-ack-v1',
    notificationsKafkaTopic: 'notifications-v2',
    installedAlertId: '5001'
  };
  const randomDataGenerator = new RandomDataGenerator();
  const container = ContainerFactory(configMock, kafkaProducerMock);

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const icdTable = container.get(ICDTable);
  const onboardingService = container.get(OnboardingService);

  beforeEach(function (done) {
    const icd = tableTestUtils.generateRecord(icdTable);

    this.currentTest.icd = icd;

    icdTable.create(icd)
      .then(() => done())
      .catch(done);
  });

  describe('#doOnDeviceInstalled()', function() {
    it('should log an install event', function (done) {

      onboardingService.doOnDeviceInstalled(this.test.icd.device_id)
        .then(() => onboardingService.retrieveCurrentState(this.test.icd.id))
        .then((state = {}) => state.event.should.equal(parseInt(TOnboardingEvent.installed)))
        .then(() => done())
        .catch(done);
    });
  });

  describe('#doOnDevicePaired()', function() {
    it('should log a pairing event', function (done) {

      onboardingService.doOnDevicePaired(this.test.icd.id, this.test.icd.location_id)
        .then(() => onboardingService.retrieveCurrentState(this.test.icd.id))
        .then((state = {}) => state.event.should.equal(parseInt(TOnboardingEvent.paired)))
        .then(() => done())
        .catch(done);
    });
  });

  describe('#doOnSystemModeUnlocked()', function() {
    it('should log a system mode unlocked event', function (done) {
      
      onboardingService.doOnSystemModeUnlocked(this.test.icd.id)
        .then(() => onboardingService.retrieveCurrentState(this.test.icd.id))
        .then((state = {}) => state.event.should.equal(parseInt(TOnboardingEvent.systemModeUnlocked)))
        .then(() => done())
        .catch(done);
    });
  });

  describe('#doOnDeviceEvent()', function() {

    function generateEvent(deviceId, eventId) {
      return {
        id: randomDataGenerator.generate('UUIDv1'),
        device_id: deviceId,
        event: {
          name: TOnboardingEvent.getNameByKey(eventId)
        }
      };
    }

    it('should log a device event and send the ack for it', function (done) {
      const event = generateEvent(this.test.icd.device_id, TOnboardingEvent.installed);

      onboardingService.doOnDeviceEvent(event)
        .then(() => onboardingService.retrieveCurrentState(this.test.icd.id))
        .then((state = {}) => state.event.should.equal(parseInt(TOnboardingEvent.installed)))
        .then(() => kafkaProducerMock.getSentMessages(configMock.eventsAckTopic)[0])
        .then(ack => ack.request_id.should.equal(event.id))
        .then(() => done())
        .catch(done);
    });

    it('should send an installed alert if the device was installed and then paired', function (done) {
      const installedEvent = generateEvent(this.test.icd.device_id, TOnboardingEvent.installed);
      const pairedEvent = generateEvent(this.test.icd.device_id, TOnboardingEvent.paired);

      onboardingService.doOnDeviceEvent(installedEvent)
        .then(() => onboardingService.doOnDeviceEvent(pairedEvent))
        .then(() => kafkaProducerMock.getSentMessages(configMock.notificationsKafkaTopic)[0].data.alarm)
        .then(alarm => alarm.reason.should.equal(parseInt(configMock.installedAlertId)))
        .then(() => done())
        .catch(done);
    });

    it('should send an installed alert if the device was paired and then installed', function (done) {
      const installedEvent = generateEvent(this.test.icd.device_id, TOnboardingEvent.installed);
      const pairedEvent = generateEvent(this.test.icd.device_id, TOnboardingEvent.paired);

      onboardingService.doOnDeviceEvent(pairedEvent)
        .then(() => onboardingService.doOnDeviceEvent(installedEvent))
        .then(() => kafkaProducerMock.getSentMessages(configMock.notificationsKafkaTopic)[0].data.alarm)
        .then(alarm => alarm.reason.should.equal(parseInt(configMock.installedAlertId)))
        .then(() => done())
        .catch(done);
    });
  });
});

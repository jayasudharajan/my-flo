const chai = require('chai');
const FloDetectResultTable = require('../../../../dist/app/services/flo-detect/FloDetectResultTable');
const FloDetectEventChronologyTable = require('../../../../dist/app/services/flo-detect/FloDetectEventChronologyTable');
const FloDetectFixtureAverageTable = require('../../../../dist/app/services/flo-detect/FloDetectFixtureAverageTable');
const FloDetectService = require('../../../../dist/app/services/flo-detect/FloDetectService');
const TFixturesData = require('../../../../dist/app/services/flo-detect/models/TFixturesData');
const TEventChronology = require('../../../../dist/app/services/flo-detect/models/TEventChronology');
const TEventFeedback = require('../../../../dist/app/services/flo-detect/models/TEventFeedback');
const TFixtureAverage = require('../../../../dist/app/services/flo-detect/models/TFixtureAverage');
const TFixturesForFeedbackData = require('../../../../dist/app/services/flo-detect/models/TFixturesForFeedbackData');
const TStatus = require('../../../../dist/app/services/flo-detect/models/TStatus');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const config = require('../../../../dist/config/config');
const tableSchemas = require('./resources/tableSchemas');
const validator = require('validator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const ContainerFactory = require('./resources/ContainerFactory');
const uuid = require('node-uuid');
const moment = require('moment');
const _ = require('lodash');
require("reflect-metadata");
const ICDService = require('../../../../dist/app/services/icd-v1_5/ICDService');
const TICD = require('../../../../dist/app/services/icd-v1_5/models/TICD');
const OnboardingService = require('../../../../dist/app/services/onboarding/OnboardingService');
const KafkaProducerMock = require('../../utils/KafkaProducerMock');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('FloDetectServiceTest', [dynamoDbTestMixin], () => {

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
  const floDetectResultTable = container.get(FloDetectResultTable);
  const floDetectEventChronologyTable = container.get(FloDetectEventChronologyTable);
  const floDetectFixtureAverageTable = container.get(FloDetectFixtureAverageTable);
  const floDetectConfig = container.get('FloDetectConfig');
  const service = container.get(FloDetectService);
  const icdService = container.get(ICDService);
  const onboardingService = container.get(OnboardingService);

  function getFixturesData(device_id) {
    const data = randomDataGenerator.generate(TFixturesData, { maybeDeleted: true });
    data.device_id = device_id;

    return data;
  }

  function getFloDetectLogEntry(device_id) {
    const data = tableTestUtils.generateRecord(floDetectResultTable);

    return Object.assign(
      data,
      {
        status: TStatus.executed,
        device_id: device_id
      }
    );
  }

  function createICD() {
    const icd = randomDataGenerator.generate(TICD);

    return icdService.create(icd)
      .then(() => icd);
  }

  function createQualifyingOnboardingEvents(icd) {

    return onboardingService.create({
      icd_id: icd.id,
      created_at: moment().subtract(floDetectConfig.floDetectMinimumDaysInstalled, 'days').toISOString(),
      event: 2
    });
  }

  function createICDBefore(done) {
    createICD()
      .then(icd => {
        this.currentTest.icd = icd;
        done();
      })
      .catch(done);
  }

  function createQualifyingOnboardingEventsBefore(done) {

    createQualifyingOnboardingEvents(this.currentTest.icd)
      .then(() => done())
      .catch(done);
  }

  describe('#logFloDetect()', function () {

    it('should save the detected fixtures', function (done) {
      const deviceId = randomDataGenerator.generate('DeviceId');
      const data = getFixturesData(deviceId);

      service.logFloDetect(deviceId, data)
        .then(() => floDetectResultTable.retrieve(floDetectResultTable.composeKeys(data)))
        .should.eventually.have.property('Item').deep.equal(
          Object.assign(
            { status: TStatus.executed },
            data
          )
        )
        .notify(done);
    });
  });

  describe('#retrieveLatestByDeviceId()', function () {

    beforeEach(createICDBefore); 

    describe('for devices out of learning mode', function () {
      
      beforeEach(createQualifyingOnboardingEventsBefore);

      it('should return the latest detected fixtures for 24 hours by device id', function (done) {
        const deviceId = this.test.icd.device_id;
        const now = moment();
        const old24Data = Object.assign(
          getFloDetectLogEntry(deviceId),
          {
            start_date: moment(now).subtract(5, 'days').toISOString(),
            end_date: moment(now).subtract(5, 'days').add(24, 'hours').toISOString()
          }
        );
        const recent24Data = Object.assign(
          getFloDetectLogEntry(deviceId),
          {
            start_date: now.toISOString(),
            end_date: moment(now).add(24, 'hours').toISOString()
          }
        );
        const recent7DayData = Object.assign(
          getFloDetectLogEntry(deviceId),
          {
            start_date: now.toISOString(),
            end_date: moment(now).add(7 * 24, 'hours').toISOString()
          }
        );

        Promise.all(
          [old24Data, recent24Data, recent7DayData]
            .map(data => floDetectResultTable.create(data))
        )
        .then(() => service.retrieveLatestByDeviceId(deviceId, 24 * 60 * 60))
        .should.eventually.deep.equal(recent24Data)
        .notify(done);
      });
    });

    // describe('for devices in learning mode', function () {
    //   it('should indicate the device is still learning', function (done) {
    //     const deviceId = this.test.icd.device_id;

    //     service.retrieveLatestByDeviceId(deviceId, 24 * 60 * 60)
    //       .should.eventually.include({ status: TStatus.learning })
    //       .notify(done);
    //   });
    // });
  });

  describe('#updateFixturesWithFeedback()', function () {
    it('should save the fixture with feedback', function (done) {
      const record = tableTestUtils.generateRecord(floDetectResultTable);
      const fixtureWithFeedback = randomDataGenerator.generate(TFixturesForFeedbackData);

      floDetectResultTable.create(record)
        .then(() => 
          service.updateFixturesWithFeedback(record.device_id, record.start_date, record.end_date, fixtureWithFeedback.fixtures)
        )
        .then(() => 
          floDetectResultTable.retrieve(floDetectResultTable.composeKeys(record))
        )
        .then(({ Item }) => {
          Item.should.have.property('status').that.equals(TStatus.feedback_submitted);
          return Item.fixtures;
        })
        .should.eventually.have.length(fixtureWithFeedback.fixtures.length)
        .notify(done);
    })
  });

  describe('#retrieveLatestByDeviceIdInDateRange', function () {
    beforeEach(createICDBefore); 

    describe('for devices out of learning mode', function () {
      
      beforeEach(createQualifyingOnboardingEventsBefore);

      it('should retrieve the latest record within the date range', function (done) {
        const deviceId = this.test.icd.device_id;
        const now = moment();
        const old24Data = Object.assign(
          getFloDetectLogEntry(deviceId),
          {
            start_date: moment(now).subtract(1, 'hours').toISOString(),
            end_date: moment(now).subtract(1, 'hours').add(24, 'hours').toISOString()
          }
        );
        const target24Data = Object.assign(
          getFloDetectLogEntry(deviceId),
          {
            start_date: now.toISOString(),
            end_date: moment(now).add(24, 'hours').toISOString()
          }
        );
        const recent24Data = Object.assign(
          getFloDetectLogEntry(deviceId),
          {
            start_date: moment(now).add(1, 'hours').toISOString(),
            end_date: moment(now).add(1, 'hours').add(24, 'hours').toISOString()
          }
        );
        const recent7DayData = Object.assign(
          getFloDetectLogEntry(deviceId),
          {
            start_date: now.toISOString(),
            end_date: moment(now).add(7 * 24, 'hours').toISOString()
          }
        );
        const rangeBegin = moment(target24Data.start_date).subtract(30, 'minutes').toISOString();
        const rangeEnd = moment(target24Data.start_date).add(30, 'minutes').toISOString();

        Promise.all(
          [old24Data, target24Data, recent24Data, recent7DayData]
            .map(data => floDetectResultTable.create(data))
        )
        .then(() => service.retrieveLatestByDeviceIdInDateRange(deviceId, 24 * 60 * 60, rangeBegin, rangeEnd))
        .should.eventually.deep.equal(target24Data)
        .notify(done);
      });

    });

    // describe('for devices in learning mode', function () {
    //   it('should indicate the device is still learning', function (done) {
    //     const deviceId = this.test.icd.device_id;
    //     const rangeBegin = moment().subtract(30, 'minutes').toISOString();
    //     const rangeEnd = moment().add(30, 'minutes').toISOString();

    //     service.retrieveLatestByDeviceIdInDateRange(deviceId, 24 * 60 * 60, rangeBegin, rangeEnd)
    //       .should.eventually.include({ status: TStatus.learning })
    //       .notify(done);
    //   });
    // });
  });

  describe('#batchCreateEventChronology', function () {
    it('should batch insert records', function (done) {
      const deviceId = randomDataGenerator.generate('DeviceId');
      const requestId = randomDataGenerator.generate('UUIDv4');
      const events = new Array(10).fill(null)
        .map(() => Object.assign(
          randomDataGenerator.generate(TEventChronology, { maybeDeleted: true }),
          {
            device_id: deviceId,
            request_id: requestId
          }
        ));

      service.batchCreateEventChronology(deviceId, requestId, events)
        .then(() => Promise.all(
          events.map(event => 
            floDetectEventChronologyTable.retrieve(event)
              .then(({ Item }) => Item)
          )
        ))
        .should.eventually.deep.equal(events)
        .notify(done);
    });
  });

  describe('#retrieveEventChronologyPage', function () {
    it('should retrieve pages of events', function (done) {
      const deviceId = randomDataGenerator.generate('DeviceId');
      const requestId = randomDataGenerator.generate('UUIDv4');
      const now = new Date().getTime();
      const events = new Array(10).fill(null)
        .map((emptyData, i) => Object.assign(
          randomDataGenerator.generate(TEventChronology, { maybeDeleted: true }),
          {
            device_id: deviceId,
            request_id: requestId,
            start: new Date(now + (i * 1000)).toISOString()
          }
        ));

      floDetectEventChronologyTable.batchCreate(events)
        .then(() => Promise.all([
          service.retrieveEventChronologyPage(deviceId, requestId, 5),
          service.retrieveEventChronologyPage(deviceId, requestId, 5, events[4].start)
        ]))
        .should.eventually.deep.equal([
          events.slice(0, 5),
          events.slice(5)
        ])
        .notify(done);
    });
  });

  describe('#updateEventChronologyWithFeedback', function () {
    it('should update the event with feedback', function (done) {
      const deviceId = randomDataGenerator.generate('DeviceId');
      const requestId = randomDataGenerator.generate('UUIDv4');
      const event = Object.assign(
        randomDataGenerator.generate(TEventChronology, { maybeDeleted: true }),
        {
          device_id: deviceId,
          request_id: requestId
        }
      );
      const feedback = randomDataGenerator.generate(TEventFeedback);

      floDetectEventChronologyTable.create(event)
        .then(() => service.updateEventChronologyWithFeedback(deviceId, requestId, event.start, feedback))
        .then(() => floDetectEventChronologyTable.retrieve(event))
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(
          Object.assign(
            {},
            event,
            { feedback }
          )
        )
        .notify(done);
    });
  });

  describe('#logFixtureAverages', function () {
    it('should log the averages', function (done) {
      const data = randomDataGenerator.generate(TFixtureAverage);

      service.logFixtureAverages(data)
        .then(() => 
          floDetectFixtureAverageTable.retrieve(
            floDetectFixtureAverageTable.composeKeys(data)
          )
        )
        .then(({ Item }) => Item)
        .should.eventually.deep.equal(data)
        .notify(done);
    }); 
  });

  describe('#retrieveLatestFixtureAverages', function () {
    it('it should retrieve the latest', function (done) {
      const deviceId = randomDataGenerator.generate('DeviceId');
      const duration = 24 * 60 * 60;
      const data = [
        randomDataGenerator.generate(TFixtureAverage),
        randomDataGenerator.generate(TFixtureAverage),
        randomDataGenerator.generate(TFixtureAverage)
      ]
      .map(averages => Object.assign(averages, { 
        device_id: deviceId, 
        duration_in_seconds: duration 
      }));

      Promise.all(
        data.map(averages => floDetectFixtureAverageTable.create(averages))
      )
      .then(() => service.retrieveLatestFixtureAverages(deviceId, duration))
      .should.eventually.deep.equal(
        _.maxBy(data, 'start_date') 
      )
      .notify(done);
    });
  });
});
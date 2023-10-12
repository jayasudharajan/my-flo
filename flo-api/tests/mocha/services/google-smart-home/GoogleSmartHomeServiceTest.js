const inversify = require('inversify');
const AWS = require('aws-sdk');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const GoogleSmartHomeService = require('../../../../dist/app/services/google-smart-home/GoogleSmartHomeService');
require('reflect-metadata');
const InfoService = require('../../../../dist/app/services/info/InfoService');
const TICD = require('../../../../dist/app/services/icd-v1_5/models/TICD');
const googleHomeFloDeviceSystemMode = require('../../../../dist/app/services/google-smart-home/models/googleHomeFloDeviceSystemMode');
const googleHomeExecuteCommandStatus = require('../../../../dist/app/services/google-smart-home/models/googleHomeExecuteCommandStatus');
const ICDService = require('../../../../dist/app/services/icd-v1_5/ICDService');
const moment = require('moment');
const Influx = require('influx');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);
const randomDataGenerator = new RandomDataGenerator();


describeWithMixins('GoogleSmartHomeServiceTest', [dynamoDbTestMixin], function () {

  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  const service = container.get(GoogleSmartHomeService);
  const icdService = container.get(ICDService);
  const infoServiceMock = container.get(InfoService);
  const influx = container.get(Influx.InfluxDB);

  describe('#processIntentRequest', function () {

    beforeEach(function (done) {
      const icd = randomDataGenerator.generate(TICD);
      const userId = randomDataGenerator.generate('UUIDv4');
      const requestId = randomDataGenerator.generate('UUIDv4');

      infoServiceMock._addDevice(icd);

      icdService.create(icd)
        .then(() => {
          this.currentTest.icd = icd;
          this.currentTest.userId = userId;
          this.currentTest.user_id = userId;
          this.currentTest._getLastKnownTelemetry = getMockTelemetry(icd);
          this.currentTest.floDevice = {device_id: icd.device_id};
          this.currentTest.requestId = requestId;
          done();
        })
        .catch(err => {
          done(err);
        });
    });

    describe('DISCONNECT', function () {

      it('should process a disconnect intent successfully', function (done) {
        service.processIntentRequest(getMockDisconnect())
          .should.eventually.be.eql([{}])
          .notify(done);
      });

    });


    describe('EXECUTE', function () {

      it('should process a execute intent successfully', function (done) {
        service.processIntentRequest(getMockedExecuteIntent())
          .then(results => {
            return results[0].payload.commands[0];
          })
          .should.eventually.have.property('status', googleHomeExecuteCommandStatus.success)
          .notify(done);
      });

      it('should return a deviceNotFound error for a non-existent device', function (done) {

        infoServiceMock._devices = [];

        service.processIntentRequest(getMockedExecuteIntent(null))
          .then(results => {
            return results[0].payload;
          })
          .should.eventually.have.property('errorCode', 'deviceNotFound')
          .notify(done);
      });

      it('should return a deviceOffline error for a non-existent telemetry', function (done) {

        influx._toggle();

        service.processIntentRequest(getMockedExecuteIntent())
          .then(results => {
            return results[0].payload;
          })
          .should.eventually.have.property('errorCode', 'deviceOffline')
          .notify(() => {
            influx._toggle();
            done();
          });
      });

    });
    describe('QUERY', function () {

      it('should process query intent successfully', function (done) {
        const icd = this.test.icd;
        service.processIntentRequest(getMockQuery(icd))
          .then(results => {
            return results[0].payload.devices[icd.device_id]
          })
          .should.eventually.have.property('did', icd.device_id)
          .notify(done);
      });

      it('should return a deviceNotFound error for a non-existent device', function (done) {
        const icd = this.test.icd;

        infoServiceMock._devices = [];

        service.processIntentRequest(getMockQuery(icd))
          .then(results => {
            return results[0].payload;
          })
          .should.eventually.have.property('errorCode', 'deviceNotFound')
          .notify(done);
      });

      it('should return a deviceOffline error for a non-existent device', function (done) {
        const icd = this.test.icd;

        influx._toggle();

        service.processIntentRequest(getMockQuery(icd))
          .then(results => {
            return results[0].payload;
          })
          .should.eventually.have.property('errorCode', 'deviceOffline')
          .notify(() => {
            influx._toggle();
            done();
          });
      });
    });

    describe('SYNC', function () {

      it('should process sync intent successfully', function (done) {
        const icd = this.test.icd;
        service.processIntentRequest(getMockSync())
          .then(results => {
            return results[0].payload.devices[0]
          })
          .should.eventually.have.property('id', icd.device_id)
          .notify(done);
      });


      it('should return an empty device list for an non-existent device', function (done) {
        const icd = this.test.icd;

        infoServiceMock._devices = [];

        service.processIntentRequest(getMockSync())
          .then(results => {
            return results[0].payload.devices
          })
          .should.eventually.deep.equal([])
          .notify(done);
      });

      it('should return an offline state for an non-existent telemetry', function (done) {
        const icd = this.test.icd;

        influx._toggle();

        service.processIntentRequest(getMockSync())
          .then(results => {
            return results[0].payload.devices[0].customData;
          })
          .should.eventually.deep.equal({ online: false })
          .then(() => influx._toggle())
          .should.notify(done);
      });
    });

  });

  function getMockedExecuteIntent(challenge = { ack: true }) {
    return {
      "requestId": "ff36a3cc-ec34-11e6-b1a0-64510650abcf",
      "inputs": [{
        "intent": "action.devices.EXECUTE",
        "payload": {
          "commands": [{
            "devices": [{
              "id": "123",
              "customData": {
                "fooValue": 74,
                "barValue": true,
                "bazValue": "lambtwirl"
              }
            }],
            "execution": [{
              "command": "action.devices.commands.OpenClose",
              "params": {
                "openPercent": 100
              },
              challenge
            }]
          }]
        }
      }]
    };
  }

  function getMockDisconnect() {
    return {
      requestId: 'ff36a3cc-ec34-11e6-b1a0-64510650abcf',
      inputs: [{
        intent: 'action.devices.DISCONNECT',
      }]
    };
  }

  function getMockQuery(icd) {
    return {
      requestId: 'ff36a3cc-ec34-11e6-b1a0-64510650abcf',
      inputs: [{
        intent: 'action.devices.QUERY',
        payload: {
          devices: [{
            id: icd.device_id,
            customData: {
              fooValue: 74,
              barValue: true,
              bazValue: 'foo'
            }
          }]
        }
      }]
    };
  }

  function getMockSync() {
    return {
      requestId: 'ff36a3cc-ec34-11e6-b1a0-64510650abcf',
      inputs: [{
        intent: 'action.devices.SYNC'
      }]
    };
  }

  function getMockTelemetry(icd) {
    return {
      time: moment().toISOString(),
      f: 37.33,
      p: 1.00,
      sm: 2,
      t: 99.44,
      v: 1,
      wf: 3.00,
      did: icd.device_id,
      online: true,
      on: true,
      currentModeSettings: {
        mode: googleHomeFloDeviceSystemMode.home
      }

    };
  }

});

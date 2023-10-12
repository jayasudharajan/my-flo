const AWS = require('aws-sdk');
const _ = require('lodash');
const chai = require('chai');
const redis = require('redis');
const sinon = require('sinon');
const uuid = require('node-uuid');

const ClientService = require('../../../../dist/app/services/client/ClientService');
const ContainerFactory = require('./resources/ContainerFactory');
const DeviceStateService = require('../../../../dist/app/services/device-state/DeviceStateService');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
const InfoService = require('../../../../dist/app/services/info/InfoService');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const tableSchemas = require('./resources/tableSchemas');
const tableTestUtils = require('../../utils/tableTestUtils');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('DeviceStateServiceTest', [ dynamoDbTestMixin ], () => {
  const container = new ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const icdTable = container.get(ICDTable);
  const clientService = container.get(ClientService);
  const infoService = container.get(InfoService);
  const s3 = container.get(AWS.S3);
  const randomUuid = container.get('RandomUuid');
  const smartHome = container.get('SmartHome');
  const redisClient = container.get(redis.RedisClient);
  const service = container.get(DeviceStateService);

  beforeEach(function (done) {
    const smartHomeClient = {
      requestSync: sinon.stub(),
      reportState: sinon.stub(),
    }
    const serviceAccountKeyJson = { type: 'service-account-key' };
    const icd = tableTestUtils.generateRecord(icdTable);
    const userId = uuid.v4();
    const clientId = '1234';

    Promise.all([
      icdTable.create(icd)
    ])
    .then(() => {
      this.currentTest.icd = icd;
      this.currentTest.userId = userId;
      this.currentTest.clientId = clientId;

      infoService.icds.retrieveByICDId
        .withArgs(icd.id)
        .resolves({ items: [ { ...icd, owner_user_id: userId } ] });

      infoService.users.retrieveAll
        .withArgs({
          filter: {
            '[geo_locations.location_id]': icd.location_id
          }
        })
        .resolves({ items: [ { id: userId } ] });

      infoService.users.retrieveByUserId
        .withArgs(userId)
        .resolves({ items: [ { devices: [icd] } ] });

      clientService.retrieveClientsByUserId
        .withArgs(userId)
        .resolves({
          data: [ { client_id: clientId } ]
        });

      s3.getObject
        .withArgs({
          Bucket: config.googleHomeTokenProviderBucket,
          Key: config.googleHomeTokenProviderKey,
        })
        .callsArgWith(1, null, { Body: Buffer.from(JSON.stringify(serviceAccountKeyJson)) });

      smartHome
        .withArgs({ jwt: serviceAccountKeyJson })
        .returns(smartHomeClient);

      const rndUuid = uuid.v4();
      randomUuid.returns(rndUuid);

      smartHomeClient.reportState
        .withArgs({
          requestId: rndUuid,
          agentUserId: userId,
          payload: {
            devices: {
              states: {
                [icd.device_id]: {
                  online: undefined, // Expected since no initial state was set.
                  currentModeSettings: { mode: undefined }, // Expected since no initial state was set.
                  openPercent: 100,
                  currentSensorStateData: [ { name: 'WaterLeak', currentSensorState: undefined } ]  // Expected since no initial state was set.
                }
              }
            }
          }
        })
        .resolves({});

      smartHomeClient.requestSync
        .withArgs(userId)
        .resolves({});

      done();
    })
    .catch(done);
  });

  describe('#forward', function () {
    it('should not forward an invalid device state to Google Smart Home API', function (done) {
      service
        .forward({})
        .should.eventually.deep.equal({
          forwarded: false,
          reason: 'Legacy or invalid device state.'
        })
        .notify(done);
    });

    it('should not fail if no clients are associated with a given user id', function (done) {
      const icd = this.test.icd;
      const userId = this.test.userId;

      clientService.retrieveClientsByUserId
        .withArgs(userId)
        .resolves({
          data: [ ]
        });

      service
        .forward({
          id: "dc402b23-e0b3-4cee-b71f-8ac64987e6a1",
          sn: "valve-state",
          did: icd.device_id,
          st: 1,
          pst: 0,
          ts: 1552304047,
          rsn: 1
        })
        .should.eventually.deep.equal({ forwarded: true })
        .notify(done);

    });

    it('should forward a valid device state to Google Smart Home API', function (done) {
      const icd = this.test.icd;

      const eventualForward = service.forward({
        id: "dc402b23-e0b3-4cee-b71f-8ac64987e6a1",
        sn: "valve-state",
        did: icd.device_id,
        st: 1,
        pst: 0,
        ts: 1552304047,
        rsn: 1
      });

      const eventualRedisAssertion = eventualForward.then(() => {
        const deferred = Promise.defer();
        redisClient.hgetall('device-state.' + icd.device_id, (err, reply) => {
          deferred.resolve(
            // No initial state for the rest of the states.
            reply.should.deep.equal({ 'valve-state': '1' })
          );
        });
        return deferred.promise;
      })

      Promise.all([
        eventualForward.should.eventually.deep.equal({ forwarded: true }),
        eventualRedisAssertion
      ]).should.notify(done);
    });
  });

  describe('#setInitialState', function () {
    it('should set the initial state for Google Smart Home', function (done) {
      const deviceId = this.test.icd.device_id;
      const telemetry = {
        did: deviceId,
        sm: 2,
        v: 1,
        online: true,
        currentSensorStateData: [ { name: 'WaterLeak', currentSensorState: 'no leak' } ]
      }

      const eventualInitialState = service.setInitialState('GoogleSmartHome', telemetry)
      const eventualRedisAssertion = eventualInitialState.then(() => {
        const deferred = Promise.defer();
        redisClient.hgetall('device-state.' + deviceId, (err, reply) => {
          deferred.resolve(
            reply.should.deep.equal({ 'system-mode': '2', 'valve-state': '1', 'leak-state': '0', 'online-state': '1' })
          );
        });
        return deferred.promise;
      });

      Promise.all([
        eventualInitialState.should.eventually.be.fulfilled,
        eventualRedisAssertion
      ]).should.notify(done);
    });
  });

  describe('#deleteDeviceState', function () {
    it('should delete device state given a user id and client id', function (done) {
      const userId = this.test.userId;
      const clientId = this.test.clientId;
      const deviceId = this.test.icd.device_id;
      const telemetry = {
        did: deviceId,
        sm: 2,
        v: 1,
        online: true,
        currentSensorStateData: [ { name: 'WaterLeak', currentSensorState: 'no leak' } ]
      }

      const eventualState = service.setInitialState('GoogleSmartHome', telemetry)
        .then(() => service.deleteDeviceState(userId, clientId));

      const eventualRedisAssertion = eventualState.then(() => {
        const deferred = Promise.defer();
        redisClient.exists('device-state.' + deviceId, (err, reply) => {
          deferred.resolve(
            reply.should.equal(0)
          );
        });
        return deferred.promise;
      });

      Promise.all([
        eventualState.should.eventually.be.fulfilled,
        eventualRedisAssertion
      ]).should.notify(done);
    });

  });

  describe('#pairingSync', function () {
    it('should issue a request sync call to Google Smart Home', function (done) {
      const icd = this.test.icd;

      service.pairingSync({ location_id: icd.location_id })
        .should.eventually.be.fulfilled
        .notify(done);
    });
  });
});
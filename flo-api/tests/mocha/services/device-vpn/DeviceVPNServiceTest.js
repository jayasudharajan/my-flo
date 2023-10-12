const chai = require('chai');
const ICDTable = require('../../../../dist/app/services/icd-v1_5/ICDTable');
const VPNWhitelistTable = require('../../../../dist/app/services/device-vpn/VPNWhitelistTable');
const DeviceVPNService = require('../../../../dist/app/services/device-vpn/DeviceVPNService');
const TVPNWhitelist = require('../../../../dist/app/services/device-vpn/models/TVPNWhitelist');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const tcustom = require('../../../../dist/app/models/definitions/CustomTypes');
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
require("reflect-metadata");

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('DeviceVPNServiceTest', [ dynamoDbTestMixin ], () => {
  const container = new ContainerFactory();
  const randomDataGenerator = new RandomDataGenerator();

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const icdTable = container.get(ICDTable);
  const table = container.get(VPNWhitelistTable);
  const service = container.get(DeviceVPNService);

  describe('#enable()', function() {
    it('should add the device to the whitelist', function (done) {
      const icd = tableTestUtils.generateRecord(icdTable);

      icdTable.create(icd)
        .then(() => {
          service
            .enable(icd.device_id)
            .then(() => {
              return table.retrieve(icd.device_id);
            })
            .then(({ Item: result }) => {
              result.device_id.should.equal(icd.device_id);
              result.start.should.below(Math.ceil(((new Date().getTime() / 1000) + 1)));
              result.end.should.above(result.start);

              done();
            }).catch(function (err) {
            done(err);
          });
        });
    });
  });

  describe('#disable()', function() {
    it('should remove the device from the whitelist', function (done) {
      const icd = tableTestUtils.generateRecord(icdTable);

      icdTable.create(icd)
        .then(() => {
          table
            .create({
              device_id: icd.device_id,
              start: 454,
              end: 566
            })
            .then(() => {
              return service.disable(icd.device_id);
            })
            .then(() => {
              return table.retrieve(icd.device_id);
            }).should.eventually.deep.equal({}).notify(done);
        });
    });
  });

  describe('#retrieveVPNConfig()', function() {
    it('should retrieve vpn config by device id', function (done) {
      const deviceId = randomDataGenerator.generate(tcustom.DeviceId);

      table
        .create({
          device_id: deviceId,
          start: 454,
          end: 566
        })
        .then(() => {
          return service.retrieveVPNConfig(deviceId);
        })
        .then(result => {
          result.device_id.should.equal(deviceId);
          result.start.should.below(Math.ceil(((new Date().getTime() / 1000) + 1)));
          result.end.should.above(result.start);
          result.vpn_enabled.should.equal(true);

          done();
        }).catch(function (err) {
        done(err);
      });
    });
  });
}, 60000);
const chai = require('chai');
const StockICDTable = require('../../../../dist/app/services/stock-icd/StockICDTable');
const DeviceSerialNumberTable = require('../../../../dist/app/services/stock-icd/DeviceSerialNumberTable');
const DeviceSerialNumberCounterTable = require('../../../../dist/app/services/stock-icd/DeviceSerialNumberCounterTable');
const StockICDService = require('../../../../dist/app/services/stock-icd/StockICDService');
const ValidationException = require('../../../../dist/app/models/exceptions/ValidationException');
const KafkaProducer = require('../../../../dist/app/services/utils/KafkaProducer');
const KafkaProducerMock = require('../../utils/KafkaProducerMock');
const clone = require('clone');
const AWS = require('aws-sdk');
const inversify = require("inversify");
const config = require('../../../../dist/config/config');
const StockICDSchema = require('../../../../dist/app/models/schemas/stockICDSchema');
const qr = require('../../../../dist/util/qrCodeUtil');
const validator = require('validator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const AWSMock = require('mock-aws-s3');
const path = require('path');
require("reflect-metadata");
const EncryptionStrategy = require('../../../../dist/app/services/utils/EncryptionStrategy');
const EncryptionStrategyMock = require('../../utils/EncryptionStrategyMock');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  [ StockICDSchema ],
  config.aws.dynamodb.prefix
);

describeWithMixins('StockICDServiceTest', [ dynamoDbTestMixin ], () => {

  const kafkaProducer = new KafkaProducerMock();
  AWSMock.config.basePath = path.resolve(__dirname, '../../resources/buckets'); // Can configure a basePath for your local buckets

  const s3 = AWSMock.S3({
    params: { }
  });

  // Declare bindings
  const container = new inversify.Container();

  container.bind(AWS.S3).toConstantValue(s3);
  container.bind(StockICDTable).to(StockICDTable);
  container.bind(StockICDService).to(StockICDService);
  container.bind(DeviceSerialNumberTable).to(DeviceSerialNumberTable);
  container.bind(DeviceSerialNumberCounterTable).to(DeviceSerialNumberCounterTable);
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
  container.bind(KafkaProducer).toConstantValue(kafkaProducer);
  container.bind(EncryptionStrategy).toConstantValue(new EncryptionStrategyMock('secret'));

  // Resolve dependencies
  const table = container.get(StockICDTable);
  const service = container.get(StockICDService);

  describe('#create()', function() {
    it('should create successfully a record', function (done) {
      const record = tableTestUtils.generateRecord(table);

      service.create(record)
        .then(function() {
          return table.retrieve({ id: record.id });
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item;
        })
        .should.eventually.deep.equal(record).notify(done);
    });

    it('should not create a record because validation errors', function (done) {
      const record = tableTestUtils.generateAnInvalidRecord(table);

      service.create(record)
        .should.be.rejectedWith(ValidationException)
        .and.notify(done);

    });
  });

  describe('#update()', function() {
    it('should update successfully a record', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.getUpdatedRecord(table, record);

      table.create(record)
        .then(function() {
          return service.update(updatedRecord.id, updatedRecord);
        })
        .then(function() {
          return table.retrieve({ id: record.id });
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item;
        })
        .should.eventually.deep.equal(updatedRecord).notify(done);
    });

    it('should not update a record because validation errors', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.generateAnInvalidRecord(table, record);

      table.create(record)
        .then(function() {
          return service.update(updatedRecord.id, updatedRecord);
        })
        .should.be.rejectedWith(ValidationException)
        .and.notify(done);
    });
  });

  describe('#patch()', function() {
    it('should patch successfully a record', function (done) {
      const record = tableTestUtils.generateRecord(table);
      const updatedRecord = tableTestUtils.getUpdatedRecord(table, record);

      table.create(record)
        .then(function() {
          return service.patch(record.id, { device_id: updatedRecord.device_id });
        })
        .then(function() {
          return table.retrieve({ id: record.id });
        })
        .then(function(returnedRecord) {
          return returnedRecord.Item.device_id;
        })
        .should.eventually.equal(updatedRecord.device_id).notify(done);
    });
  });

  describe('#retrieve()', function() {
    it('should return a record by id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function() {
          return service.retrieve(record.id);
        })
        .then(function(result) {
          return result;
        }).should.eventually.deep.equal(record).notify(done);
    });
  });

  describe('#remove()', function() {
    it('should remove an existing record', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function() {
          return service.remove(record.id);
        })
        .then(function() {
          return table.retrieve({ id: record.id });
        })
        .then(function(result) {
          return result;
        }).should.eventually.deep.equal({}).notify(done);
    });
  });

  describe('#archive()', function() {
    it('should archive an existing record', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function() {
          return service.remove(record.id);
        })
        .then(function() {
          return table.retrieve({ id: record.id });
        })
        .then(function(result) {
          return result;
        }).should.eventually.deep.equal({}).notify(done);
    });
  });

  describe('#retrieveQrCodeById()', function() {
    it('should return the qr code by id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function() {
          return service.retrieveQrCode(record.id);
        })
        .then(function(result) {
          return result;
        }).should.eventually.deep.equal({ qr_code_data_png: record.qr_code_data_png }).notify(done);
    });
  });

  describe('#retrieveQrCodeByDeviceId()', function() {
    it('should return the qr code by device id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      record.device_id = 'test-qr-code';

      table.create(record)
        .then(function() {
          return service.retrieveQrCodeByDeviceId(record.device_id);
        })
        .then(function(result) {
          return result;
        }).should.eventually.property('qr_code_data_svg')
        .have.string('</svg>').and
        .have.string('<svg').notify(done);
    });
  });

  describe('#retrieveWebSocketTokenByDeviceId()', function() {
    it('should return the web socket token by device id', function (done) {
      const record = tableTestUtils.generateRecord(table);

      table.create(record)
        .then(function() {
          return service.retrieveWebSocketTokenByDeviceId(record.device_id);
        })
        .then(function(result) {
          return result;
        }).should.eventually.deep.equal({
        new_device : false,
        websocket_token: record.icd_login_token,
        websocket_tls_enabled: true    // we may need to check if TLS certs exist.. need a better logic
      }).notify(done);
    });
  });

  describe('#generateStockICD()', function() {
    it('should send stock icd request to kafka', function (done) {
      const record = tableTestUtils.generateRecord(table);

      record.websocket_cert = "data";
      record.websocket_key = "data";

      service.generateStockICD(
        record.device_id,
        record.wlan_mac_id,
        {
          ssid: record.wifi_ssid,
          password: record.wifi_password
        },
        record.sku,
        {
          key: record.websocket_key,
          cert: record.websocket_cert
        },
        record.icd_login_token
      ).then(function(result) {
        const message = kafkaProducer.getSentMessages(config.pkiKafkaTopic)[0];
        
        validator.isUUID(message.pairing_code).should.equal(true);
        validator.isISO8601(message.requested_at).should.equal(true);

        message.device_id.should.equal(record.device_id);

        done();

        return message;
      }).catch(function (err) {
        done(err);
      });
    });
  });
});
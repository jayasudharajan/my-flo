const _ = require('lodash');
const chai = require('chai');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');
const PairingService = require('../../../../dist/app/services/pairing/PairingService');
const NotFoundException = require('../../../../dist/app/services/utils/exceptions/NotFoundException');
const MQTTCertService = require('../../../../dist/app/services/mqtt-cert/MQTTCertService');
const ICDService = require('../../../../dist/app/services/icd-v1_5/ICDService');
const TICD = require('../../../../dist/app/services/icd-v1_5/models/TICD');
const StockICDService = require('../../../../dist/app/services/stock-icd/StockICDService');
const TStockICD = require('../../../../dist/app/services/stock-icd/models/TStockICD');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('PairingServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(PairingService);
  const icdService = container.get(ICDService);
  const stockICDService = container.get(StockICDService);
  const mqttCertService = container.get(MQTTCertService);

  describe('#retrievePairingDataByICDId', function () {
    beforeEach(function (done) {
      const icd = Object.assign(
        randomDataGenerator.generate(TICD),
        { is_paired: true }
      );
      const stockICD = Object.assign(
        randomDataGenerator.generate(TStockICD),
        { device_id: icd.device_id }
      );

      Promise.all([
        mqttCertService.retrieveCAFile(stockICD.flo_ca_version),
        icdService.create(icd),
        stockICDService.create(stockICD)
      ])
      .then(([caFile]) => {
        this.currentTest.icd = icd;
        this.currentTest.stockICD = stockICD;
        this.currentTest.caFile = caFile;

        done();
      })
      .catch(err => done(err));
    })

    it('should retrieve the QR data', function (done) {

      service.retrievePairingDataByICDId(this.test.icd.id)
        .should.eventually.deep.equal(
          service._createPairingData(this.test.stockICD, this.test.caFile)
        )
        .notify(done);
    });

    it('should fail if the pairing does not exist', function (done) {
      service.retrievePairingDataByICDId(randomDataGenerator.generate('UUIDv4'))
        .should.eventually.be.rejectedWith(NotFoundException)
        .notify(done);
    });

    it('should fail if the QR data does not exist', function (done) {
      const icd = Object.assign(
        randomDataGenerator.generate(TICD),
        { is_paired: true }
      );

      icdService.create(icd)
        .then(() => service.retrievePairingDataByICDId(icd.id))
        .should.eventually.be.rejectedWith(NotFoundException)
        .notify(done);
    });
  });

}); 
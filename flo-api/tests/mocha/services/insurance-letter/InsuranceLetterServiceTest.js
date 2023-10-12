const chai = require('chai');
const InsuranceLetterRequestLogTable = require('../../../../dist/app/services/insurance-letter/InsuranceLetterRequestLogTable');
const InsuranceLetterPDFCreator = require('../../../../dist/app/services/insurance-letter/InsuranceLetterPDFCreator');
const InsuranceLetterService = require('../../../../dist/app/services/insurance-letter/InsuranceLetterService');
const AccountTable = require('../../../../dist/app/services/account-v1_5/AccountTable');
const LocationTable = require('../../../../dist/app/services/location-v1_5/LocationTable');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');
const UserDetailTable = require('../../../../dist/app/services/user-account/UserDetailTable');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const tableSchemas = require('./resources/tableSchemas');
const validator = require('validator');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const tableTestUtils = require('../../utils/tableTestUtils');
const ContainerFactory = require('./resources/ContainerFactory');
const _ = require('lodash');
const moment = require('moment');
require('reflect-metadata');

chai.use(require('chai-datetime'));

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

describeWithMixins('InsuranceLetterServiceTest', [ dynamoDbTestMixin ], () => {

  const container = new ContainerFactory();

  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const accountTable = container.get(AccountTable);
  const userTable = container.get(UserTable);
  const userDetailTable = container.get(UserDetailTable);
  const locationTable = container.get(LocationTable);
  const insuranceLetterRequestLogTable = container.get(InsuranceLetterRequestLogTable);
  const insuranceLetterPDFCreator = container.get(InsuranceLetterPDFCreator);
  const service = container.get(InsuranceLetterService);

  function generateRegistry(location_id, overrides) {
    const requestLog = _.assign(
      tableTestUtils.generateRecord(insuranceLetterRequestLogTable),
      {
        expiration_date: moment.utc().add(1, 'day').toISOString(),
        renewal_date: moment.utc().add(1, 'day').toISOString(),
        location_id,
        s3_bucket: "some-bucket",
        s3_key: "some-key"
      }
    );

    return _.assign(requestLog, overrides);
  }

  beforeEach(function (done) {
    const account = tableTestUtils.generateRecord(accountTable);
    const location = _.assign(tableTestUtils.generateRecord(locationTable), { account_id: account.id });
    const user = _.assign(tableTestUtils.generateRecord(userTable), { id: account.owner_user_id });
    const userDetail =  _.assign(
      tableTestUtils.generateRecord(userDetailTable, { maybeIgnored: false }), { user_id: user.id }
    );

    Promise.all([
      accountTable.create(account),
      locationTable.create(location),
      userTable.create(user),
      userDetailTable.create(userDetail)
    ])
      .then(() => {
        this.currentTest.account = account;
        this.currentTest.location = location;
        this.currentTest.user = user;
        this.currentTest.userDetail = userDetail;
        done();
      })
      .catch(done);
  });

  describe('#generate()', function() {
    it('should call the PDF Generator to generate the pdf when there is no valid pdf link', function(done) {
      service
        .generate(this.test.location.location_id, this.test.user.id)
        .then(() => {
          const result = insuranceLetterPDFCreator.getPDFGenerationRequests()[0];

          insuranceLetterPDFCreator.clean();

          return Promise.all([
            insuranceLetterRequestLogTable.retrieveLatest({ location_id: this.test.location.location_id }),
            result
          ]);
        })
        .then(([requestLogResult, user]) =>
          ({ user_id: user.user_id, location_id: requestLogResult.Items[0].location_id })
        )
        .should.eventually.deep.equal({
          user_id: this.test.user.id, location_id: this.test.location.location_id
        })
        .notify(done);
    });


    it('should call the lambda function to generate the pdf when current date is after renewal date', function(done) {
      const requestLog = generateRegistry(this.test.location.location_id, {
        renewal_date: moment.utc().subtract(1, 'day').toISOString()
      });

      insuranceLetterRequestLogTable
        .create(requestLog)
        .then(() => service.generate(this.test.location.location_id, this.test.user.id))
        .then(() => {
          const result = insuranceLetterPDFCreator.getPDFGenerationRequests()[0];

          insuranceLetterPDFCreator.clean();

          return Promise.all([
            insuranceLetterRequestLogTable.retrieveLatest({ location_id: this.test.location.location_id }),
            result
          ]);
        })
        .then(([requestLogResult, user]) =>
          ({ user_id: user.user_id, location_id: requestLogResult.Items[0].location_id })
        )
        .should.eventually.deep.equal({
          user_id: this.test.user.id, location_id: this.test.location.location_id
        })
        .notify(done);
    });

    it('should call the lambda function to generate the pdf when current date is after expiration date', function(done) {
      const requestLog = generateRegistry(this.test.location.location_id, {
        expiration_date: moment.utc().subtract(1, 'day').toISOString()
      });

      insuranceLetterRequestLogTable
        .create(requestLog)
        .then(() => service.generate(this.test.location.location_id, this.test.user.id))
        .then(() => {
          const result = insuranceLetterPDFCreator.getPDFGenerationRequests()[0];

          insuranceLetterPDFCreator.clean();

          return Promise.all([
            insuranceLetterRequestLogTable.retrieveLatest({ location_id: this.test.location.location_id }),
            result
          ]);
        })
        .then(([requestLogResult, user]) =>
          ({ user_id: user.user_id, location_id: requestLogResult.Items[0].location_id })
        )
        .should.eventually.deep.equal({
          user_id: this.test.user.id, location_id: this.test.location.location_id
        })
        .notify(done);
    });

    it('should not call the lambda function to generate the pdf when there is a valid pdf link', function(done) {
      const requestLog = generateRegistry(this.test.location.location_id);

      insuranceLetterRequestLogTable
        .create(requestLog)
        .then(() => service.generate(this.test.location.location_id, this.test.user.id))
        .then(() => {
          const result = insuranceLetterPDFCreator.getPDFGenerationRequests();

          insuranceLetterPDFCreator.clean();

          return result;
        })
        .should.eventually.deep.equal([])
        .notify(done);
    });
  });

  describe('#getDownloadInfo()', function() {
    it('should retrieve a ready status and the pdf link if there is valid requestLog with the pdf link information', function(done) {
      const requestLog = generateRegistry(this.test.location.location_id);

      insuranceLetterRequestLogTable
        .create(requestLog)
        .then(() => service.getDownloadInfo(this.test.location.location_id))
        .should.eventually.deep.equal({
          status: "ready",
          document_download_url: `${requestLog.s3_bucket}/${requestLog.s3_key}`,
          date_redeemed: requestLog.date_redeemed,
          expiration_date: requestLog.expiration_date,
          redeemed_by_user_id: requestLog.redeemed_by_user_id,
          renewal_date: requestLog.renewal_date
        })
        .notify(done);

    });

    it('should retrieve not found status if there is no valid requestLog', function(done) {
      const requestLog = generateRegistry(this.test.location.location_id, {
        expiration_date: moment.utc().subtract(1, 'day').toISOString()
      });

      insuranceLetterRequestLogTable
        .create(requestLog)
        .then(() => service.getDownloadInfo(this.test.location.location_id))
        .should.eventually.deep.equal({ status: "not-found" })
        .notify(done);
    });

    it('should retrieve processing status if there is a valid requestLog without the pdf link information', function(done) {
      const requestLog = generateRegistry(this.test.location.location_id, {
        s3_bucket: null,
        s3_key: null
      });

      insuranceLetterRequestLogTable
        .create(requestLog)
        .then(() => service.getDownloadInfo(this.test.location.location_id))
        .should.eventually.deep.equal({ status: "processing" })
        .notify(done);
    });
  });

  describe('#redeem()', function() {
    it('should update the registry with the redeem date and user', function(done) {
      const requestLog = generateRegistry(this.test.location.location_id, {
        s3_bucket: 'some-bucket',
        s3_key: 'some-key',
        date_redeemed: undefined,
        redeemed_by_user_id: undefined
      });

      insuranceLetterRequestLogTable
        .create(requestLog)
        .then(() => service.redeem(this.test.location.location_id, this.test.user.id))
        .then(() => insuranceLetterRequestLogTable.retrieveLatest({ location_id: this.test.location.location_id }))
        .then(registryResult => {
          const registry = registryResult.Items[0];
          const now = moment();
          const from = now.subtract(1, 'second').toDate();
          const to = now.add(1, 'second').toDate();

          moment(registry.date_redeemed).toDate().should.withinTime(from, to);
          registry.redeemed_by_user_id.should.equal(this.test.user.id);

          done();
        })
        .catch(done);
    });
  });

  describe('#regenerate()', function() {
    it('should call the PDF Generator to regenerate the pdf always', function(done) {
      const oldRegistry = generateRegistry(this.test.location.location_id);

      insuranceLetterRequestLogTable
        .create(oldRegistry)
        .then(() => service.regenerate(this.test.location.location_id, this.test.user.id))
        .then(() => {
          const result = insuranceLetterPDFCreator.getPDFGenerationRequests()[0];

          insuranceLetterPDFCreator.clean();

          return Promise.all([
            insuranceLetterRequestLogTable.retrieveLatest({ location_id: this.test.location.location_id }),
            result
          ]);
        })
        .then(([requestLogResult, user]) =>
          ({ user_id: user.user_id, location_id: requestLogResult.Items[0].location_id })
        )
        .should.eventually.deep.equal({
          user_id: this.test.user.id, location_id: this.test.location.location_id
        })
        .notify(done);
    });
  });
});
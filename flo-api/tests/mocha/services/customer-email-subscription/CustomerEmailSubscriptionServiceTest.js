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
const CustomerEmailSubscriptionService = require('../../../../dist/app/services/customer-email-subscription/CustomerEmailSubscriptionService');
const CustomerEmailSubscriptionTable = require('../../../../dist/app/services/customer-email-subscription/CustomerEmailSubscriptionTable');
const TCustomerEmailSubscription = require('../../../../dist/app/services/customer-email-subscription/models/TCustomerEmailSubscription');
const CustomerEmailTable = require('../../../../dist/app/services/customer-email-subscription/CustomerEmailTable');
const TCustomerEmail = require('../../../../dist/app/services/customer-email-subscription/models/TCustomerEmail');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('CustomerEmailSubscriptionServiceTest', [ dynamoDbTestMixin ], function () {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(CustomerEmailSubscriptionService);
  const customerEmailSubscriptionTable = container.get(CustomerEmailSubscriptionTable);
  const customerEmailTable = container.get(CustomerEmailTable);

  describe('#retrieve', function () {

    it('should retrieve the record', function (done) {
      const customerEmailSubscription = randomDataGenerator.generate(TCustomerEmailSubscription);

      customerEmailSubscriptionTable.create(customerEmailSubscription)
        .then(() => service.retrieve(customerEmailSubscription.user_id, customerEmailSubscription.email_id))
        .then(result => _.pick(result, Object.keys(customerEmailSubscription)))
        .should.eventually.deep.equal(customerEmailSubscription)
        .notify(done);
    });

    it('should retrieve an empty result', function (done) {
      const userId = randomDataGenerator.generate('UUIDv4');

      service.retrieve(userId)
        .should.eventually.deep.equal({})
        .notify(done);
    });
  }); 

  describe('#retrieveAllEmails', function () {

    beforeEach(function (done) {
      const customerEmails = [
        randomDataGenerator.generate(TCustomerEmail, { maybeDeleted: true }),
        randomDataGenerator.generate(TCustomerEmail, { maybeDeleted: true }),
        randomDataGenerator.generate(TCustomerEmail, { maybeDeleted: true })
      ];
      const promises = customerEmails.map(customerEmail => customerEmailTable.create(customerEmail));

       Promise.all(promises)
        .then(() => {
          this.currentTest.customerEmails = customerEmails;
          done();
        })
        .catch(err => {
          done(err);
        });
    });

    it('should retrieve all records', function (done) {

      service.retrieveAllEmails()
        .then(({ data: results }) => results.map(result => _.pick(result, Object.keys(TCustomerEmail.meta.props))))
        .should.eventually.have.deep.members(this.test.customerEmails)
        .notify(done);
    });
  });

  describe('#updateSubscriptions', function () {

    it('should update an existing subscription record', function (done) {
      const customerEmailSubscription = randomDataGenerator.generate(TCustomerEmailSubscription);
      const emailId = Object.keys(customerEmailSubscription.subscriptions)[0];

      customerEmailSubscriptionTable.create(customerEmailSubscription)
        .then(() => service.updateSubscriptions(customerEmailSubscription.user_id, { [emailId]: !customerEmailSubscription.subscriptions[emailId] }))
        .then(() => customerEmailSubscriptionTable.retrieve(customerEmailSubscription.user_id))
        .then(({ Item }) => _.pick(Item, Object.keys(TCustomerEmailSubscription.meta.props)))
        .should.eventually.deep.equal(Object.assign(
          {}, 
          customerEmailSubscription,
          {
            subscriptions: Object.assign(
              {},
              customerEmailSubscription.subscriptions,
              { [emailId]: !customerEmailSubscription.subscriptions[emailId] }
            )
          }
        ))
        .notify(done);
    });

    it('should create a subscription record if none exists', function (done) {
      const customerEmailSubscription = randomDataGenerator.generate(TCustomerEmailSubscription);

      service.updateSubscriptions(customerEmailSubscription.user_id, customerEmailSubscription.subscriptions)
        .then(() => customerEmailSubscriptionTable.retrieve(customerEmailSubscription.user_id))
        .then(({ Item }) => _.pick(Item, Object.keys(TCustomerEmailSubscription.meta.props)))
        .should.eventually.deep.equal(customerEmailSubscription)
        .notify(done);
    });
  });
});
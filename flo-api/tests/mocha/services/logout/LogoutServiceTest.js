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
const PushNotificationTokenService = require('../../../../dist/app/services/push-notification-token/PushNotificationTokenService');
const OAuth2Service = require('../../../../dist/app/services/oauth2/OAuth2Service');
const LogoutService = require('../../../../dist/app/services/logout/LogoutService');
const ClientService = require('../../../../dist/app/services/client/ClientService');
const TPushNotificationToken = require('../../../../dist/app/services/push-notification-token/models/TPushNotificationToken');
const InvalidTokenException =  require('../../../../dist/app/services/oauth2/models/exceptions/InvalidTokenException');

require('reflect-metadata');

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('LogoutServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  const service = container.get(LogoutService);
  const oauth2Service = container.get(OAuth2Service);
  const pushNotificationTokenService = container.get(PushNotificationTokenService);
  const clientService = container.get(ClientService);

  describe('#logout', function () {
    beforeEach(function (done) {
      const pushNotificationTokenData = randomDataGenerator.generate(TPushNotificationToken);
      const userId = pushNotificationTokenData.user_id;
      const clientId = pushNotificationTokenData.client_id;
      const mobileDeviceId = pushNotificationTokenData.mobile_device_id;

      this.currentTest.userId = userId;
      this.currentTest.clientId = clientId;
      this.currentTest.mobileDeviceId = mobileDeviceId;

      Promise.all([
        oauth2Service.createEndUserAccessToken({ client_id: clientId }, { id: userId }),
        pushNotificationTokenService.create(pushNotificationTokenData)
      ])
      .then(([{ token, metadata: { token_id } }]) => {
        
        this.currentTest.accessTokenId = token_id;
        this.currentTest.accessToken = token;

        return oauth2Service.createRefreshToken({ client_id: clientId }, { id: userId }, token_id)
      })
      .then(({ token }) => {
        this.currentTest.refreshToken = token;

        done();
      })
      .catch(err => {
        console.log(err);
        done(err);
      });
    });

    it('should revoke access, refresh, and push notification token', function (done) {
      const accessTokenId = this.test.accessTokenId;
      const userId = this.test.userId;
      const clientId = this.test.clientId;
      const mobileDeviceId = this.test.mobileDeviceId;

      return service.logout(accessTokenId, userId, clientId, mobileDeviceId)
        .then(() => 
          Promise.all([
            oauth2Service.verifyAccessToken(this.test.accessToken)
              .should.eventually.be.rejectedWith(InvalidTokenException),
            oauth2Service.verifyRefreshToken(this.test.refreshToken)
              .should.eventually.be.rejectedWith(InvalidTokenException),
            pushNotificationTokenService.retrieve({ client_id: clientId, mobile_device_id: mobileDeviceId })
              .should.eventually.have.property('is_disabled', 1),
            clientService.retrieveClientUser(clientId, userId, true)
              .should.eventually.have.property('is_disabled', 1)
          ])
        )
        .should.eventually.notify(done);
    });

    it('should revoke access and refresh token even if no mobile device id is specified', function (done) {
      const accessTokenId = this.test.accessTokenId;
      const userId = this.test.userId;
      const clientId = this.test.clientId;
      const mobileDeviceId = this.test.mobileDeviceId;

      return service.logout(accessTokenId, userId, clientId)
        .then(() => 
          Promise.all([
            oauth2Service.verifyAccessToken(this.test.accessToken)
              .should.eventually.be.rejectedWith(InvalidTokenException),
            oauth2Service.verifyRefreshToken(this.test.refreshToken)
              .should.eventually.be.rejectedWith(InvalidTokenException)
          ])
        )
        .should.eventually.notify(done);
    });
  });
}); 
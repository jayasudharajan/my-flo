const _ = require('lodash');
const chai = require('chai');
const UserTable = require('../../../../dist/app/services/user-account/UserTable');
const ClientService = require('../../../../dist/app/services/client/ClientService');
const TClient = require('../../../../dist/app/services/client/models/TClient');
const TScope = require('../../../../dist/app/services/oauth2/models/TScope');
const ScopeTable = require('../../../../dist/app/services/oauth2/ScopeTable');
const OAuth2Service = require('../../../../dist/app/services/oauth2/OAuth2Service');
const InvalidTokenException = require('../../../../dist/app/services/oauth2/models/exceptions/InvalidTokenException');
const UnauthorizedClientException = require('../../../../dist/app/services/oauth2/models/exceptions/UnauthorizedClientException');
const AccessDeniedException = require('../../../../dist/app/services/oauth2/models/exceptions/AccessDeniedException');
const InvalidRequestException = require('../../../../dist/app/services/oauth2/models/exceptions/InvalidRequestException');
const TokenExpiredException = require('../../../../dist/app/services/oauth2/models/exceptions/TokenExpiredException');
const OAuth2Config = require('../../../../dist/app/services/oauth2/OAuth2Config');
const NotFoundException = require('../../../../dist/app/services/utils/exceptions/NotFoundException');
const InvalidUsernamePasswordException = require('../../../../dist/app/services/authentication/models/exceptions/InvalidUsernamePasswordException');
const ACLService = require('../../../../dist/app/services/utils/ACLService');
const AWS = require('aws-sdk');
const inversify = require('inversify');
const config = require('../../../../dist/config/config');
const describeWithMixins = require('../../utils/describeWithMixins');
const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
const RandomDataGenerator = require('../../utils/RandomDataGenerator');
const ContainerFactory = require('./resources/ContainerFactory');
const tableSchemas = require('./resources/tableSchemas');

require('reflect-metadata');

chai.use(require('chai-passport-strategy'));

const dynamoDbTestMixin = new DynamoDbTestMixin(
  config.aws.dynamodb.endpoint,
  tableSchemas,
  config.aws.dynamodb.prefix
);

const randomDataGenerator = new RandomDataGenerator();

describeWithMixins('OAuth2ServiceTest', [ dynamoDbTestMixin ], () => {
  // Declare bindings
  const container = ContainerFactory();
  container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());

  // Resolve dependencies
  const userTable = container.get(UserTable);
  const clientService = container.get(ClientService);
  const service = container.get(OAuth2Service);
  const oauth2Config = container.get(OAuth2Config);
  const scopeTable = container.get(ScopeTable);
  const aclService = container.get(ACLService);

  describe('#handlePasswordGrant', function () {

    beforeEach(function (done) {
      Promise.all([
        createTestClient.call(this, { grant_types: ['password'] }),
        createTestUser.call(this)
      ])
      .then(() => done())
      .catch(done);
    });

    it('should grant an access token and refresh token', function (done) {
      const client = this.test.client;
      const { email: username, password } = this.test.user;

      service.handlePasswordGrant(client, username, password)
        .should.eventually
        .include.keys('access_token', 'refresh_token', 'expires_in')
        .notify(done);
    });

    it('should fail with an invalid username/password exception with an invalid password', function (done) {
      const client = this.test.client;
      const { email: username } = this.test.user;

      service.handlePasswordGrant(client, username, randomDataGenerator.generate('Password'))
        .should.eventually.be.rejectedWith(InvalidUsernamePasswordException)
        .notify(done);
    });


    it('should fail with an invalid username/password exception with an invalid email', function (done) {
      const client = this.test.client;
      const { password } = this.test.user;

      service.handlePasswordGrant(client, randomDataGenerator.generate('Email'), password)
        .should.eventually.be.rejectedWith(InvalidUsernamePasswordException)
        .notify(done);
    });

    it('should deny access to an unauthorized user when login is restricted', function (done) {
      const client = Object.assign(this.test.client, { is_login_restricted: true });
      const user = this.test.user;
      const { email: username, password } = this.test.user;

      clientService.update(client)
        .then(() => service.handlePasswordGrant(client, username, password))
        .should.eventually.be.rejectedWith(AccessDeniedException)
        .notify(done);
    });

    it('should allow access to an authorized user when login is restricted', function (done) {
      const client = Object.assign(this.test.client, { is_login_restricted: true });
      const user = this.test.user;
      const { email: username, password } = this.test.user;

      Promise.all([
        clientService.update(client),
        aclService.allow(aclService.formatUserId(user.id, client.client_id), `Client:${ client.name }`, 'login')
      ])
      .then(() => service.handlePasswordGrant(client, username, password))
      .should.eventually.include.keys('access_token', 'refresh_token', 'expires_in')
      .notify(done);
    });
  });

  describe('#handleRefreshTokenGrant', function () {

    beforeEach(function (done) {
      Promise.all([
        createTestClient.call(this, { grant_types: ['password', 'refresh_token'] }),
        createTestUser.call(this)
      ])
      .then(() => done())
      .catch(done);
    });

    it('should grant an access token and refresh token', function (done) {
      const client = this.test.client;
      const { email: username, password } = this.test.user;

      service.handlePasswordGrant(client, username, password)
        .then(({ refresh_token }) => service.handleRefreshTokenGrant(client, refresh_token))
        .should.eventually
        .include.keys('access_token', 'refresh_token', 'expires_in')
        .notify(done);
    });

    it('should register an association between the client and user', function (done) {
      const client = this.test.client;
      const { email: username, password, id: userId } = this.test.user;

      service.handlePasswordGrant(client, username, password)
        .then(({ refresh_token }) => service.handleRefreshTokenGrant(client, refresh_token))
        .then(() => clientService.retrieveClientUser(client.client_id, userId))
        .should.eventually
        .include({ client_id: client.client_id, user_id: userId })
        .notify(done);    
    });

    it('should fail to grant an access token and refresh token with an invalid refresh token', function (done) {
      const client = this.test.client;
      const { email: username, password } = this.test.user;

      service.handlePasswordGrant(client, username, password)
        .then(() => service.handleRefreshTokenGrant(client, randomDataGenerator.generate('String')))
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });

    it('should not allow a refresh token to be reused after the linger period', function (done) {
      const client = this.test.client;
      const { email: username, password } = this.test.user;

      Promise.all([
        service.handlePasswordGrant(client, username, password),
        oauth2Config.getRefreshTokenLinger()
      ])
      .then(([{ refresh_token }, lingerSeconds]) => 
        service.handleRefreshTokenGrant(client, refresh_token)
          .then(() => new Promise((resolve, reject) => 
            setTimeout(() => 
              service.handleRefreshTokenGrant(client, refresh_token)
                .then(result => resolve(result))
                .catch(err => reject(err)),
              (lingerSeconds + 1) * 1000
            )
          ))
      )
      .should.eventually.be.rejectedWith(TokenExpiredException)
      .notify(done);
    });

    it('should allow a refresh token to be reused during the linger period', function (done) {
      const client = this.test.client;
      const { email: username, password } = this.test.user;

      Promise.all([
        service.handlePasswordGrant(client, username, password),
        oauth2Config.getRefreshTokenLinger()
      ])
      .then(([{ refresh_token }, lingerSeconds]) => 
        service.handleRefreshTokenGrant(client, refresh_token)
          .then(() => new Promise((resolve, reject) => 
            setTimeout(() => 
              service.handleRefreshTokenGrant(client, refresh_token)
                .then(result => resolve(result))
                .catch(err => reject(err)),
              (lingerSeconds - 1) * 1000
            )
          ))
      )
      .should.eventually
      .include.keys('access_token', 'refresh_token', 'expires_in')
      .notify(done);
    });

    it('should not allow a refresh token if the client id does not match', function (done) {
      const client1 = this.test.client;
      const client2 = Object.assign({}, client1, { client_id: randomDataGenerator.generate('UUIDv4') });
      const { email: username, password } = this.test.user;


      service.handlePasswordGrant(client1, username, password)
        .then(({ refresh_token }) => 
          service.handleRefreshTokenGrant(client2, refresh_token)
        )
        .should.eventually.be.rejected
        .notify(done);
    });

    it('should invalidate the refreshed access token', function (done) {
      const client = this.test.client;
      const { email: username, password } = this.test.user;

      service.handlePasswordGrant(client, username, password)
        .then(({ access_token, refresh_token }) => 
          service.handleRefreshTokenGrant(client, refresh_token)
            .then(() => service.verifyAccessToken(access_token))
        )
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });

    it('should not allow a refresh token to be used if it exceeds the client limit', function (done) {
      const client = this.test.client;
      const { email: username, password } = this.test.user;

      oauth2Config.getRefreshTokenLimit()
        .then(limit => Promise.all(
          Array(limit + 1).fill(null).map((empty, i) => {
            const deferred = Promise.defer();

            setTimeout(() => 
              service.handlePasswordGrant(client, username, password)
                .then(results => deferred.resolve(results))
                .catch(err => deferred.reject(err)),
              i * 1000
            );

            return deferred.promise;
          })
        ))
        .then(([{ refresh_token }]) => 
          service.handleRefreshTokenGrant(client, refresh_token)
        )
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });

    it('should allow a refresh token to be used if its under the client limit', function (done) {
      const client1 = this.test.client;
      const { email: username, password } = this.test.user;
      const context = { currentTest: {} };

      createTestClient.call(context, { grant_types: ['password', 'refresh_token'], client_id: randomDataGenerator.generate('UUIDv4') })
        .then(() => oauth2Config.getRefreshTokenLimit())
        .then(limit => Promise.all(
          [client1, context.currentTest.client]
            .map(client => 
              Array(limit).fill(null).map((empty, i) => {
                const deferred = Promise.defer();

                setTimeout(() => 
                  service.handlePasswordGrant(client, username, password)
                    .then(results => deferred.resolve(results))
                    .catch(err => deferred.reject(err)),
                  i * 1000
                );

                return deferred.promise;
            }))
            .reduce((acc, arr) => acc.concat(arr), [])
        ))
        .then(([{ refresh_token }]) => 
          service.handleRefreshTokenGrant(client1, refresh_token)
        )
        .should.eventually.include.keys('access_token', 'refresh_token', 'expires_in')
        .notify(done);
    });
  });

  describe('#issueSingleUseAccessToken', function () {
    beforeEach(function (done) {
      Promise.all([
        createTestClient.call(this),
        createTestUser.call(this)
      ])
      .then(() => done())
      .catch(done);
    });

    it('it should grant a valid access token', function (done) {
      const client = this.test.client;
      const user = this.test.user;

      service.issueSingleUseAccessToken(client, user)
        .then(({ token }) => {
          const deferred = Promise.defer();

          chai.passport.use(service.getAuthStrategy())
            .success((user, { user_id }) => deferred.resolve(user_id))
            .fail(err => deferred.reject(err))
            .error(err => deferred.reject(err))
            .req(req => req.headers.authorization = `Bearer ${ token }`)
            .authenticate();
        
          return deferred.promise;
        })
        .should.eventually.equal(user.id)
        .notify(done);

    });

    it('should not allow the token to be reused', function (done) {
      const client = this.test.client;
      const user = this.test.user;

      service.issueSingleUseAccessToken(client, user)
        .then(({ token }) => {
          const deferred = Promise.defer();

          chai.passport.use(service.getAuthStrategy())
            .success(() => deferred.resolve(token))
            .fail(err => deferred.reject(err))
            .error(err => deferred.reject(err))
            .req(req => req.headers.authorization = `Bearer ${ token }`)
            .authenticate();
        
          return deferred.promise;
        })
        .then(token => {
          const deferred = Promise.defer();

          chai.passport.use(service.getAuthStrategy())
            .success(() => deferred.reject(new Error('Should not allow the token to be reused')))
            .fail(err => deferred.reject(err))
            .error(err => deferred.reject(err))
            .req(req => req.headers.authorization = `Bearer ${ token }`)
            .authenticate();
        
          return deferred.promise;
        })
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });
  });

  describe('#handleClientCredentialsGrant', function () {
    beforeEach(function (done) {
      createTestClient.call(this, {
        grant_types: ['client_credentials']
      })
      .then(() => done())
      .catch(done);
    });

    it('should grant an access token to the client', function (done) {
      const client = this.test.client;

      service.handleClientCredentialsGrant(client)
        .then(({ access_token }) => service.verifyAccessToken(access_token))
        .should.be.fulfilled
        .notify(done);
    });
  });

  describe('#getClientPasswordAuthStrategy', createClientAuthStrategyTest(
    () => service.getClientPasswordAuthStrategy(),
    client => (req => { 
        req.body = Object.assign(
          { client_id: client.client_id },
          client.client_secret ? { client_secret: client.client_secret } : {}
        );
    })
  ));

  describe('#getClientBasicAuthStrategy', createClientAuthStrategyTest(
    () => service.getClientBasicAuthStrategy(),
    client => (req => {
        const base64Credentials = Buffer.from(`${ client.client_id }:${ client.client_secret || ' ' }`).toString('base64');
        req.headers.authorization = `Basic ${ base64Credentials }`;
    })
  ));

  describe('#handleAuthorizationCodeRequest', function () {
    beforeEach(function (done) {
      const redirectUri = randomDataGenerator.generate('String');
      Promise.all([
        createTestClient.call(this, { 
          grant_types: ['authorization_code'],
          redirect_uri_whitelist: [redirectUri]
        }),
        createTestUser.call(this)
      ])
      .then(() => done())
      .catch(done);
    });

    it('should grant an authorization code', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeRequest(client, user, redirectUri, true)
        .should.eventually.have.property('authorization_code')
        .notify(done);
    });

    it('should not grant an authorization code to an unauthorized client', function (done) {
      const client = Object.assign(
        randomDataGenerator.generate(TClient, { maybeDeleted: true }),
        { grant_types: ['client_credentials'] }
      );
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeRequest(client, user, redirectUri, true)
        .should.eventually.be.rejectedWith(UnauthorizedClientException)
        .notify(done);
    });

    it('should deny access if a client refuses the authorization', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeRequest(client, user, redirectUri, false)
        .should.eventually.be.rejectedWith(AccessDeniedException)
        .notify(done);
    });

    it('should not grant an authorization code if the redirect URI is not whitelisted', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = randomDataGenerator.generate('String');

      service.handleAuthorizationCodeRequest(client, user, redirectUri, true)
        .should.eventually.be.rejectedWith(InvalidRequestException)
        .notify(done);
    });

    it('should deny access to an unauthorized user when login is restricted', function (done) {
      const client = Object.assign(this.test.client, { is_login_restricted: true });
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      clientService.update(client)
        .then(() => service.handleAuthorizationCodeRequest(client, user, redirectUri, true))
        .should.eventually.be.rejectedWith(AccessDeniedException)
        .notify(done);
    });

    it('should allow access to an authorized user when login is restricted', function (done) {
      const client = Object.assign(this.test.client, { is_login_restricted: true });
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      Promise.all([
        clientService.update(client),
        aclService.allow(aclService.formatUserId(user.id, client.client_id), `Client:${ client.name }`, 'login')
      ])
      .then(() => service.handleAuthorizationCodeRequest(client, user, redirectUri, true))
      .should.eventually.have.property('authorization_code')
      .notify(done);
    });
  });

 describe('#handleAuthorizationCodeGrant', function () {
    beforeEach(function (done) {
      const redirectUri = randomDataGenerator.generate('String');

      Promise.all([
        createTestClient.call(this, {
          grant_types: ['authorization_code'],
          redirect_uri_whitelist: [redirectUri]
        }),
        createTestUser.call(this)
      ])
      .then(() => done())
      .catch(done);
    });

    it('should exchange an authorization code for an access token and refresh token', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeRequest(client, user, redirectUri, true)
        .then(({ authorization_code }) => service.handleAuthorizationCodeGrant(client, authorization_code, redirectUri))
        .should.eventually.include.keys('access_token', 'refresh_token', 'expires_in')
        .notify(done);
    });

    it('should fail if the redirect URI does not match', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeRequest(client, user, redirectUri, true)
        .then(({ authorization_code }) => service.handleAuthorizationCodeGrant(client, authorization_code, randomDataGenerator.generate('String')))
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);
    });

    it('should fail if the client does not match', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeRequest(client, user, redirectUri, true)
        .then(({ authorization_code }) => service.handleAuthorizationCodeGrant(randomDataGenerator.generate(TClient, { maybeDeleted: true }), authorization_code, randomDataGenerator.generate('String')))
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);      
    });

    it('should fail with an invalid authorization code', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeGrant(client, randomDataGenerator.generate('String'), redirectUri)
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);      
    });

    it('should not allow the authorization code to be reused', function (done) {
      const client = this.test.client;
      const user = this.test.user;
      const redirectUri = this.test.client.redirect_uri_whitelist[0];

      service.handleAuthorizationCodeRequest(client, user, redirectUri, true)
        .then(({ authorization_code }) => 
          service.handleAuthorizationCodeGrant(client, authorization_code, redirectUri)
            .then(() => authorization_code)
        )
        .then(authorization_code => service.handleAuthorizationCodeGrant(client, authorization_code, redirectUri))
        .should.eventually.be.rejectedWith(InvalidTokenException)
        .notify(done);     
    });
  });

 describe('#retrieveAuthorizationDetails', function () {
  beforeEach(function (done) {
    const scope = randomDataGenerator.generate(TScope);
    const client = Object.assign(
      randomDataGenerator.generate(TClient, { maybeDeleted: true }),
      {
        grant_types: ['authorization_code'],
        scopes: [scope.scope_name]
      }
    );

    this.currentTest.scope = scope;
    this.currentTest.client = client;

    Promise.all([
      clientService.create(client),
      scopeTable.create(scope)
    ])
    .then(() => done())
    .catch(done);
  });

  it('should retrieve authorization details', function (done) {
    const client = this.test.client;
    const scope = this.test.scope;

    service.retrieveAuthorizationDetails(client.client_id)
      .should.eventually.deep.equal({
        client_id: client.client_id,
        client_name: client.name,
        scopes: [scope]
      })
      .notify(done);
  });

  it('should error if client does not exist', function (done) {

      service.retrieveAuthorizationDetails(randomDataGenerator.generate('UUIDv4'))
        .should.eventually.be.rejectedWith(NotFoundException)
        .notify(done);
  });
 });
 
  function createTestUser(done) {
    this.currentTest.user = {
      id: randomDataGenerator.generate('UUIDv4'),
      email: randomDataGenerator.generate('Email'),
      password: randomDataGenerator.generate('Password'),
      is_active: true
    };

    return userTable.create(this.currentTest.user);
  }

  function createTestClient(data) {
    const client = Object.assign(
      randomDataGenerator.generate(TClient, { maybeDeleted: true }),
      {
        client_secret: randomDataGenerator.generate('String')
      },
      data
    );

    this.currentTest.client = client;

    return clientService.create(client);
  }

  function createClientAuthStrategyTest(getStrategy, buildReq) {
    return function () {

      beforeEach(function (done) {
        createTestClient.call(this)
          .then(() => done())
          .catch(done);
      });

      it('should authenticate a client that has a secret', function (done) {
        const client = this.test.client;

        useChaiPassport(getStrategy, buildReq(client))
          .then(({ client: { client_id  } }) => client_id)
          .should.eventually.equal(client.client_id)
          .notify(done);
      });

      it('should authenticate a client that does not have a secret', function (done) {
        const client = _.omit(this.test.client, ['client_secret']);

        clientService.update(client)
          .then(() => useChaiPassport(getStrategy, buildReq(client)))       
          .then(({ client: { client_id  } }) => client_id)
          .should.eventually.equal(client.client_id)
          .notify(done);
      });

      it('should not authenticate a client that has a secret that does not provide one', function (done) {
        const client = _.omit(this.test.client, ['client_secret']);

        useChaiPassport(getStrategy, buildReq(client))
          .should.eventually.be.rejected
          .notify(done);
      });

      it('should not authenticate a client that provides the wrong secret', function (done) {
        const client = Object.assign(this.test.client, { client_secret: randomDataGenerator.generate('String') });

        useChaiPassport(getStrategy, buildReq(client))
          .should.eventually.be.rejected
          .notify(done);
      });
    };

    function useChaiPassport(getStrategy, buildReq) {
      const deferred = Promise.defer();

      chai.passport.use(getStrategy())
        .success((client, info) => deferred.resolve({ client, info }))
        .fail(err => deferred.reject(err))
        .error(err => deferred.reject(err))
        .req(req => buildReq(req))
        .authenticate();

      return deferred.promise;
    }
  }
});
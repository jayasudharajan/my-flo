// const chai = require('chai');
// const AuthMiddleware = require('../../../../dist/app/services/utils/AuthMiddleware');
// const ACLMiddleware = require('../../../../dist/app/services/utils/ACLMiddleware');
// const AuthMiddlewareMock = require('../../utils/AuthMiddlewareMock');
// const ACLMiddlewareMock = require('../../utils/ACLMiddlewareMock');
// const AWS = require('aws-sdk');
// const inversify = require("inversify");
// const DirectiveResponseLogSchema = require('../../../../dist/app/models/schemas/DirectiveResponseLogSchema');
// const ICDSchema = require('../../../../dist/app/models/schemas/icdSchema');
// const ICDTable = require('../../../../dist/app/models/ICDTable');
// const ICDService = require('../../../../dist/app/services/icd/ICDService');
// const requestTypes = require('../../../../dist/app/services/directive-response/models/requestTypes');
// const TDirectiveResponseLog = require('../../../../dist/app/services/directive-response/models/TDirectiveResponseLog');
// const DirectiveResponseTable = require('../../../../dist/app/services/directive-response/DirectiveResponseTable');
// const DirectiveResponseService = require('../../../../dist/app/services/directive-response/DirectiveResponseService');
// const config = require('../../../../dist/config/config');
// const describeWithMixins = require('../../utils/describeWithMixins');
// const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
// const AppServerTestMixin = require('../../utils/AppServerTestMixin');
// const tableTestUtils = require('../../utils/tableTestUtils');
// const AppServerFactory = require('../../../../dist/AppServerFactory');
// const RandomDataGenerator = require('../../utils/RandomDataGenerator');
// const AppServerTestUtils = require('../../utils/AppServerTestUtils');
// const redis = require('redis');
// const mockRedis = require('redis-mock');
// const uuid = require('node-uuid');
// const _ = require('lodash');
// require("reflect-metadata");



// const dynamoDbTestMixin = new DynamoDbTestMixin(
//   config.aws.dynamodb.endpoint,
//   [ ICDSchema, DirectiveResponseLogSchema ],
//   config.aws.dynamodb.prefix
// );

// // Declare bindings
// const container = new inversify.Container();
// container.bind(ICDTable).to(ICDTable);
// container.bind(ICDService).to(ICDService);
// container.bind(DirectiveResponseTable).to(DirectiveResponseTable);
// container.bind(DirectiveResponseService).to(DirectiveResponseService);
// container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
// container.bind(redis.RedisClient).toConstantValue(mockRedis.createClient());
// container.bind(AuthMiddleware).toConstantValue(new AuthMiddlewareMock());
// container.bind(ACLMiddleware).toConstantValue(new ACLMiddlewareMock());

// const appServerFactory = new AppServerFactory(AppServerTestUtils.withRandomPort(config), container);
// const appServerTestMixin = new AppServerTestMixin(appServerFactory);

// describeWithMixins('DirectiveResponseHttpTest', [ dynamoDbTestMixin, appServerTestMixin ], () => {

//   // Resolve dependencies
//   const directiveResponseTable =  container.get(DirectiveResponseTable);
//   const icdTable =  container.get(ICDTable);
//   const app = appServerFactory.instance();
//   const endpoint = '/api/v1/directiveresponselogs/device/:device_id';

//   const randomDataGenerator = new RandomDataGenerator();

//   describe('POST ' + endpoint, function() {
//     it('should create successfully a record', function (done) {
//       const icd = getNewICD();
//       const directiveResponse = randomDataGenerator.generate(
//         requestTypes.logDirectiveResponse.body,
//         { maybeIgnored: true }
//       );
//       const endpointWithParams = endpoint.replace(':device_id', icd.device_id);

//       directiveResponse.device_id = icd.device_id;

//       icdTable.create(icd).then(() => {
//         chai.request(app)
//           .post(endpointWithParams)
//           .send(directiveResponse)
//           .then(response => {
//             response.should.deep.include({ status: 200 });

//             const retrieveParams = {
//               icd_id: icd.id,
//               created_at: response.body.created_at
//             };

//             return directiveResponseTable
//               .retrieve(retrieveParams)
//               .then(result => result.Item.directive_id);

//           }).should.eventually.deep.equal(directiveResponse.directive_id).notify(done);
//       })
//     });
//   });
// });

// function getNewICD() {
//   const randomDataGenerator = new RandomDataGenerator();

//   return {
//     id: uuid.v4(),
//     location_id: uuid.v4(),
//     is_paired: true,
//     device_id: randomDataGenerator.generate('DeviceId')
//   };
// }

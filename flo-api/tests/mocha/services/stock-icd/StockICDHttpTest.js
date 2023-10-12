// const chai = require('chai');
// const StockICDTable = require('../../../../dist/app/services/stock-icd/StockICDTable');
// const TStockICD = require('../../../../dist/app/services/stock-icd/models/TStockICD');
// const AuthMiddleware = require('../../../../dist/app/services/utils/AuthMiddleware');
// const ACLMiddleware = require('../../../../dist/app/services/utils/ACLMiddleware');
// const AuthMiddlewareMock = require('../../utils/AuthMiddlewareMock');
// const ACLMiddlewareMock = require('../../utils/ACLMiddlewareMock');
// const AWS = require('aws-sdk');
// const inversify = require("inversify");
// const StockICDSchema = require('../../../../dist/app/models/schemas/stockICDSchema');
// const config = require('../../../../dist/config/config');
// const describeWithMixins = require('../../utils/describeWithMixins');
// const DynamoDbTestMixin = require('../../utils/DynamoDbTestMixin');
// const AppServerTestMixin = require('../../utils/AppServerTestMixin');
// const tableTestUtils = require('../../utils/tableTestUtils');
// const AppServerFactory = require('../../../../dist/AppServerFactory');
// const HttpCrudTestUtils = require('../../utils/HttpCrudTestUtils');
// const AppServerTestUtils = require('../../utils/AppServerTestUtils');
// const _ = require('lodash');
// require("reflect-metadata");

// const dynamoDbTestMixin = new DynamoDbTestMixin(
//   config.aws.dynamodb.endpoint,
//   [ StockICDSchema ],
//   config.aws.dynamodb.prefix
// );

// // Declare bindings
// const container = new inversify.Container();
// container.bind(StockICDTable).to(StockICDTable);
// container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbTestMixin.getDynamoDbDocumentClient());
// container.bind(AuthMiddleware).toConstantValue(new AuthMiddlewareMock());
// container.bind(ACLMiddleware).toConstantValue(new ACLMiddlewareMock());

// const appServerFactory = new AppServerFactory(AppServerTestUtils.withRandomPort(config), container);
// const appServerTestMixin = new AppServerTestMixin(appServerFactory);

// describeWithMixins('StockICDHttpTest', [ dynamoDbTestMixin, appServerTestMixin ], () => {

//   // Resolve dependencies
//   const table = container.get(StockICDTable);
//   const crudTests = new HttpCrudTestUtils(appServerFactory.instance(), table, '/api/v1/stockicds');

//   //This gives the user the ability to add each test individually in case that endpoint do not implements
//   // all of them
//   /*
//   crudTests
//     .create()
//     .retrieve()
//     .update()
//     .patch()
//     .delete()
//     .archive();
//   */

//   //This run the whole crud test suite
//   crudTests
//     .all();
// });



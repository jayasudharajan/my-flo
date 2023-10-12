const DynamoDbUtils = require('./DynamoDbUtils');
const _ = require('lodash');
const localDynamo = require('local-dynamo');

class DynamoDbTestMixin {

  constructor(dynamoEndpoint, schemas, schemaPrefix) {
    const dynamoDbUtils = new DynamoDbUtils(dynamoEndpoint);

    this.dynamoDbUtils = dynamoDbUtils;
    this.schemas = _.map(schemas, function(schema) {
      return dynamoDbUtils.getNormalizedSchema(schemaPrefix, schema);
    });
  }

  getDynamoDbDocumentClient() {
    return this.dynamoDbUtils.getDynamoDbDocumentClient();
  }

  getDynamoDb() {
    return this.dynamoDbUtils.getDynamoDb();
  }

  before() {
    this.dynamo = localDynamo.launch(
      {
        port: 4567,
        sharedDb: true,
        heap: '512m'
      });
  }

  after() {
    this.dynamo.kill();
  }

  beforeEach(done) {
    // Create required tables
    this.dynamoDbUtils
      .createTables(this.schemas)
      .then(() => done())
      .catch(done);
  };

  afterEach(done) {
    this.dynamoDbUtils
      .deleteTables(this.schemas)
      .then(() => done())
      .catch(done);
  };
}

module.exports = DynamoDbTestMixin;
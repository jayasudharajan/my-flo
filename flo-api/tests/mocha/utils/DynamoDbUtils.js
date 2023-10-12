const AWS = require('aws-sdk');

class DynamoDbUtils {
  constructor(dynamoEndpoint) {
    const options = {
      region: 'us-west-2',
      endpoint: dynamoEndpoint,
      accessKeyId: 'foo',
      secretAccessKey: 'bar',
      sslEnabled: false
    };
    this.dynamoDB = new AWS.DynamoDB(options);
    this.dynamoDBDocumentClient = new AWS.DynamoDB.DocumentClient(options);
  }

  getDynamoDb() {
    return this.dynamoDB;
  }

  getDynamoDbDocumentClient() {
    return this.dynamoDBDocumentClient;
  }

  createTable(schema) {
    return new Promise((resolve, reject) =>
      this.getDynamoDb().createTable(schema, (err, res) => err ? reject(err) : resolve(res))
    );
  }

  deleteTable(schema) {
    return new Promise((resolve, reject) =>
      this.getDynamoDb().deleteTable({ TableName: schema.TableName }, (err, res) => err ? reject(err) : resolve(res))
    );
  }

  createTables(tableSchemas) {
    const promises = tableSchemas.map(tableSchema =>
      this.createTable(tableSchema)
    );

    return Promise.all(promises);
  }

  deleteTables(tableSchemas) {
    const promises = tableSchemas.map(tableSchema =>
      this.deleteTable(tableSchema)
    );

    return Promise.all(promises);
  }

  getNormalizedSchema(prefix, schema) {
    var tableName = schema.TableName;

    if(!schema.TableName.startsWith(prefix)) {
      tableName = prefix + schema.TableName;
    }

    return Object.assign({}, schema, { TableName: tableName });
  }
}

module.exports = DynamoDbUtils;
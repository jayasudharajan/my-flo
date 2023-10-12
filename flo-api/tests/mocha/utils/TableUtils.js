const AWS = require('aws-sdk');
const _ = require('lodash');

class TableUtils {

  constructor(dynamoDBConfig) {
    this.dynamo = new AWS.DynamoDB(dynamoDBConfig);
  }

  createTable(schema) {
    return new Promise((resolve, reject) =>
      this.dynamo.createTable(schema, (err, res) => err ? reject(err) : resolve(res))
    );
  }

  deleteTable(schema) {
    return new Promise((resolve, reject) =>
      this.dynamo.deleteTable({ TableName: schema.TableName }, (err, res) => err ? reject(err) : resolve(res))
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

module.exports = TableUtils;
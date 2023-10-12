import AWS from 'aws-sdk';
import _ from 'lodash';

class DynamoDbClient {

  constructor(
    private dynamoDb: AWS.DynamoDB.DocumentClient,
    private tablePrefix: string | undefined
  ) {}

  public scan(tableName: string, process: (item: any) => Promise<any>): void {
    const dynamoDb = this.dynamoDb;
    const params = {
      TableName: this.tablePrefix + tableName
    };

    function onScan(err: any, data: any): void {
      if (err) {
        console.error("Unable to scan the table. Error JSON:", JSON.stringify(err, null, 2));
      } else {
        console.log("Scan succeeded. Items: " + data.Items.length);
        Promise
          .all(data.Items.map((item: any) => process(item)))
          .then(() => {
            // continue scanning if we have more items, because
            // scan can retrieve a maximum of 1MB of data
            if (typeof data.LastEvaluatedKey != "undefined") {
              console.log("Scanning for more...");
              dynamoDb.scan({ ...params, ExclusiveStartKey: data.LastEvaluatedKey }, onScan);
            }
          });
      }
    }
    dynamoDb.scan(params, onScan);
  }

  public scanBatchWithFilter(
    tableName: string,
    filterExpression: string,
    expressionAttributeValues: any,
    process: (items: any) => void,
    onDone: () => void
  ): void {

    const dynamoDb = this.dynamoDb;
    const params = {
      TableName: this.tablePrefix + tableName,
      FilterExpression: filterExpression,
      ExpressionAttributeValues: expressionAttributeValues
    };

    function onScan(err: any, data: any): void {
      if (err) {
        console.error("Unable to scan the table. Error JSON:", JSON.stringify(err, null, 2));
      } else {
        process(data.Items);

        // continue scanning if we have more items, because
        // scan can retrieve a maximum of 1MB of data
        if (typeof data.LastEvaluatedKey != "undefined") {
          dynamoDb.scan({ ...params, ExclusiveStartKey: data.LastEvaluatedKey }, onScan);
        } else {
          onDone();
        }
      }
    }

    //onDone();

    dynamoDb.scan(params, onScan);
  }

  public async get<T>(tableName: string, key: KeyMap): Promise<T | null> {
    const { Item } = await this._get(tableName, key).promise();

    return _.isEmpty(Item) ? null : Item as T;
  }

  public async exists(tableName: string, key: KeyMap): Promise<boolean> {
    const { Item } = await this._get(tableName, key).promise();

    return !_.isEmpty(Item);
  }

  public async query<T>(tableName: string, queryOptions: DynamoDbQuery): Promise<T[]> {
    const { Items } = await this._query(tableName, queryOptions).promise();

    return Items as T[];
  }

  private _get(tableName: string, key: KeyMap): AWS.Request<AWS.DynamoDB.DocumentClient.GetItemOutput, AWS.AWSError> {
    return this.dynamoDb.get({
      TableName: this.tablePrefix + tableName,
      Key: key
    });
  }

  private _query(tableName: string, queryOptions: DynamoDbQuery): AWS.Request<AWS.DynamoDB.DocumentClient.QueryOutput, AWS.AWSError> {
    return this.dynamoDb.query({
      TableName: this.tablePrefix + tableName,
      ...queryOptions
    });
  }
}

export type KeyMap = { [key: string]: any };

export type DynamoDbQuery = Partial<AWS.DynamoDB.DocumentClient.QueryInput>;

export default DynamoDbClient;

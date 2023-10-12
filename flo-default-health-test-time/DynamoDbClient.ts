import AWS from 'aws-sdk';
import _ from 'lodash'

class DynamoDbClient {

  constructor(
    private dynamoDb: AWS.DynamoDB.DocumentClient,
    private tablePrefix: string | undefined
  ) {}

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

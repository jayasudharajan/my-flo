import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import TDeviceSerialNumberCounter from './models/TDeviceSerialNumberCounter'
import DIFactory from  '../../../util/DIFactory';
import AWS from 'aws-sdk';

class DeviceSerialNumberCounterTable extends ValidationMixin(TDeviceSerialNumberCounter, DynamoTable)  {
  constructor(dynamoDbClient) {
    super('DeviceSerialNumberCounter', 'date', undefined, dynamoDbClient);
  }

  retrieve(date) {

    return this.dynamoDbClient.get({
      TableName: this.tableName,
      Key: {
        date: date
      },
      ConsistentRead: true
    })
    .promise();
  }

  retrieveAndIncrement(date) {
    return this.dynamoDbClient.update({
      TableName: this.tableName,
      Key: {
        date: date
      },
      UpdateExpression: 'SET #counter = if_not_exists(#counter, :neg_one) + :one',
      ExpressionAttributeNames: {
        '#counter': 'counter'
      },
      ExpressionAttributeValues: {
        ':neg_one': -1, // so that (-1 + 1) == 0 for the first value
        ':one': 1
      },
      ReturnValues: 'ALL_NEW'
    })
    .promise();
  }
}

export default new DIFactory(DeviceSerialNumberCounterTable, [AWS.DynamoDB.DocumentClient]);
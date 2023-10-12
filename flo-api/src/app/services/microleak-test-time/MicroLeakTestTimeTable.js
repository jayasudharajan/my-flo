import DIFactory from '../../../util/DIFactory';
import AWS from 'aws-sdk';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import TMicroLeakTestTime from './models/TMicroLeakTestTime'

class MicroLeakTestTimeTable extends ValidationMixin(TMicroLeakTestTime, LogDynamoTable) {

  constructor(dynamoDbClient) {
    super('MicroLeakTestTime', 'device_id', 'created_at', dynamoDbClient);
  }

  retrieveByIsDeployed(isDeployed) {
    const params = {

      TableName: this.tableName,
      IndexName: 'IsDeployedCreatedAtDeviceIdIndex',
      KeyConditionExpression: 'is_deployed = :is_deployed',
      ExpressionAttributeValues: {
        ':is_deployed': isDeployed ? 1 : 0,
      },
      ScanIndexForward: false,
    };
    return this.dynamoDbClient.query(params).promise();
  }
}

export default new DIFactory(MicroLeakTestTimeTable, [AWS.DynamoDB.DocumentClient]);
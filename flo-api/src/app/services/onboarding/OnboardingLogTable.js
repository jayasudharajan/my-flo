import LogDynamoTable from '../../models/LogDynamoTable';
import DIFactory from  '../../../util/DIFactory';
import { ValidationMixin } from '../../models/ValidationMixin';
import TOnboardingLog from './models/TOnboardingLog';
import AWS from 'aws-sdk';

class OnboardingLogTable extends LogDynamoTable {

  constructor(dynamoDbClient) {
    super('OnboardingLog', 'icd_id', 'created_at', dynamoDbClient);
  }

  retrieveCurrentState(icdId) {
  	return this.dynamoDbClient.query({
  		TableName: this.tableName,
  		IndexName: 'EventIndex',
  		KeyConditionExpression: 'icd_id = :icd_id',
  		ExpressionAttributeValues: {
  			':icd_id': icdId
  		},
	 	ScanIndexForward: false,
	 	Limit: 1
  	})
  	.promise()
  	.then(({ Items: [onboardingLog] }) => onboardingLog);
  }

  marshal(data) {
  	return super.marshal({ ...data, event: parseInt(data.event) });
  }

  retrieveByIcdId(icdId) {
    return this.dynamoDbClient.query({
      TableName: this.tableName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': icdId
      }
    })
    .promise();
  }

  retrieveByIcdIdEvent(icdId, event) {

    return this.dynamoDbClient.query({
      TableName: this.tableName,
      IndexName: 'EventIndex',
      KeyConditionExpression: 'icd_id = :icd_id AND #event = :event',
      ExpressionAttributeNames: {
        '#event': 'event'
      },
      ExpressionAttributeValues: {
        ':icd_id': icdId,
        ':event': parseInt(event)
      }
    })
    .promise()
    .then(({ Items: [onboardingLog] }) => onboardingLog)    
  }
}

export default new DIFactory(OnboardingLogTable, [AWS.DynamoDB.DocumentClient]);
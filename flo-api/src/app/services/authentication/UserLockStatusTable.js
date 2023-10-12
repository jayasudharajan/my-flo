import AWS from 'aws-sdk';
import TUserLockStatus from './models/TUserLockStatus';
import DIFactory from  '../../../util/DIFactory';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'

class UserLockStatusTable extends ValidationMixin(TUserLockStatus, LogDynamoTable) {
	constructor(dynamoDbClient) {
		super(
			'UserLockStatus',
			'user_id',	
			'created_at', 
			dynamoDbClient, 
		);
	}

	retrieveByUserId(userId) {
		return client.query({
			TableName: this.tableName,
			KeyConditionExpression: 'user_id = :user_id',
			ExpressionAttributeValues: {
				':user_id': userId
			}
		}).promise();
	} 
}

export default new DIFactory(UserLockStatusTable, [AWS.DynamoDB.DocumentClient]);
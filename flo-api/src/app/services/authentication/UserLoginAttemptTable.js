import AWS from 'aws-sdk';
import TUserLoginAttempt from './models/TUserLoginAttempt';
import DIFactory from  '../../../util/DIFactory';
import LogDynamoTable from '../../models/LogDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'

class UserLoginAttemptTable extends ValidationMixin(TUserLoginAttempt, LogDynamoTable) {
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

export default new DIFactory(UserLoginAttemptTable, [AWS.DynamoDB.DocumentClient]);
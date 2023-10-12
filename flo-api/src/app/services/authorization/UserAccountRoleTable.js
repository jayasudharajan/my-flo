import AWS from 'aws-sdk';
import TUserAccountRole from './models/TUserAccountRole';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class UserAccountRoleTable extends ValidationMixin(TUserAccountRole, DynamoTable) {
	constructor(dynamoDbClient) {
		super(
			'UserAccountRole',
			'user_id',	
			'account_id', 
			dynamoDbClient 
		);
	}

	retrieveByUserId(userId) {
		const params = {
			TableName: this.tableName,
			KeyConditionExpression: 'user_id = :user_id',
			ExpressionAttributeValues: {
				':user_id': userId
			}			
		};

		return this.dynamoDbClient.query(params).promise();
	}
}

export default new DIFactory(UserAccountRoleTable, [AWS.DynamoDB.DocumentClient]);
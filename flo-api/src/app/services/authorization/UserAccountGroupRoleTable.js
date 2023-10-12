import AWS from 'aws-sdk';
import TUserAccountGroupRole from './models/TUserAccountGroupRole';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class UserAccountGroupRoleTable extends ValidationMixin(TUserAccountGroupRole, DynamoTable) {
	constructor(dynamoDbClient) {
		super(
			'UserAccountGroupRole',
			'user_id',	
			'group_id', 
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

	retrieveByGroupId(groupId) {
		const params = {
			TableName: this.tableName,
			IndexName: 'GroupIdIndex',
			KeyConditionExpression: 'group_id = :group_id',
			ExpressionAttributeValues: {
				':group_id': groupId
			}
		};

		return this.dynamoDbClient.query(params).promise();
	}
}

export default new DIFactory(UserAccountGroupRoleTable, [AWS.DynamoDB.DocumentClient]);
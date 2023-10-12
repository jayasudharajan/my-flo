import AWS from 'aws-sdk';
import TUserSystemRole from './models/TUserSystemRole';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class UserSystemRoleTable extends ValidationMixin(TUserSystemRole, DynamoTable) {
	constructor(dynamoDbClient) {
		super(
			'UserSystemRole',
			'user_id',	
			undefined, 
			dynamoDbClient, 
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

export default new DIFactory(UserSystemRoleTable, [AWS.DynamoDB.DocumentClient]);
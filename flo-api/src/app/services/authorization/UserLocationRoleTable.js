import AWS from 'aws-sdk';
import TUserLocationRole from './models/TUserLocationRole';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class UserLocationRoleTable extends ValidationMixin(TUserLocationRole, DynamoTable) {
	constructor(dynamoDbClient) {
		super(
			'UserLocationRole',
			'user_id',	
			'location_id', 
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

export default new DIFactory(UserLocationRoleTable, [AWS.DynamoDB.DocumentClient]);
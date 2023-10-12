import _ from 'lodash';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import { ValidationMixin, validateMethod } from '../../models/ValidationMixin';
import DynamoTable from '../../models/DynamoTable';
import TAccount from './models/TAccount';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';

class AccountTable extends ValidationMixin(TAccount, DynamoTable) {
	constructor(dynamoDbClient) {
		super('Account', 'id', undefined, dynamoDbClient);
	}

	marshal(data) {
		return super.marshal(_.pickBy(data, value => value));
	}

	retrieveByOwnerUserId(userId) {
		const params = {
			TableName: this.tableName,
			IndexName: 'OwnerUser',
			KeyConditionExpression: 'owner_user_id = :owner_user_id',
			ExpressionAttributeValues: {
				':owner_user_id': userId
			}
		};

		return this.dynamoDbClient.query(params).promise();
	}

	retrieveByGroupId(groupId) {
		const params = {
			TableName: this.tableName,
			IndexName: 'AccountGroup',
			KeyConditionExpression: 'group_id = :group_id',
			ExpressionAttributeValues: {
				':group_id': groupId
			}
		};

		return this.dynamoDbClient.query(params).promise();
	}
}

validateMethod(
	AccountTable.prototype,
	'retrieveByOwnerUserId',
	[tcustom.UUIDv4]
);

validateMethod(
	AccountTable.prototype,
	'retrieveByGroupId',
	[tcustom.UUIDv4]
);

export default DIFactory(AccountTable, [AWS.DynamoDB.DocumentClient]);
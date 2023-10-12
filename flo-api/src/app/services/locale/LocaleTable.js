import uuid from 'uuid';
import AWS from 'aws-sdk';
import DynamoTable from '../../models/DynamoTable';
import moment from 'moment';
import DIFactory from  '../../../util/DIFactory';
import ValidationMixin from '../../models/ValidationMixin'
import TLocale from './models/TLocale';

class LocaleTable extends ValidationMixin(TLocale, DynamoTable) {
	constructor(dynamoDbClient) {
		super('Locale', 'locale', undefined, dynamoDbClient);
	}

	listAll() {
		return this._withExhaustivePaging(
			ExclusiveStartKey => 
				this.dynamoDbClient.scan({
					TableName: this.tableName,
					ProjectionExpression: '#locale,#name',
					ExclusiveStartKey,
					ExpressionAttributeNames: {
						'#locale': 'locale',
						'#name': 'name'
					}
				})
				.promise()
		);
	}
}

export default new DIFactory(LocaleTable, [AWS.DynamoDB.DocumentClient]);
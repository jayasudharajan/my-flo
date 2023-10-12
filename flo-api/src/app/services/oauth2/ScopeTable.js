import AWS from 'aws-sdk';
import TScope from './models/TScope';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class ScopeTable extends ValidationMixin(TScope, DynamoTable) {
	constructor(dynamoDbClient) {
		super(
			'Scope',
			'scope_name',	
			undefined, 
			dynamoDbClient
		);
	}
}

export default new DIFactory(ScopeTable, [AWS.DynamoDB.DocumentClient]);
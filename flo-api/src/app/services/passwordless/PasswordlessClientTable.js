import AWS from 'aws-sdk';
import TPasswordlessClient from './models/TPasswordlessClient';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';

class PasswordlessClientTable extends ValidationMixin(TPasswordlessClient, DynamoTable) {
	constructor(dynamoDbClient) {
		super(
			'PasswordlessClient',
			'client_id',	
			undefined, 
			dynamoDbClient
		);
	}
}

export default new DIFactory(PasswordlessClientTable, [AWS.DynamoDB.DocumentClient]);
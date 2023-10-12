import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import TokenMetadataTable from './TokenMetadataTable';
import ValidationMixin from '../../models/ValidationMixin'
import TAuthorizationCodeMetadata from './models/TAuthorizationCodeMetadata';

class AuthorizationCodeMetadataTable extends ValidationMixin(TAuthorizationCodeMetadata, TokenMetadataTable) {
	constructor(dynamoDbClient) {
		super(
			'AuthorizationCodeMetadata',
			dynamoDbClient 
		);
	}
}

export default new DIFactory(AuthorizationCodeMetadataTable, [AWS.DynamoDB.DocumentClient]);
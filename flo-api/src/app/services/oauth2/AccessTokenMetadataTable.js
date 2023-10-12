import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import TokenMetadataTable from './TokenMetadataTable';
import ValidationMixin from '../../models/ValidationMixin'
import TAccessTokenMetadata from './models/TAccessTokenMetadata';

class AccessTokenMetadataTable extends ValidationMixin(TAccessTokenMetadata, TokenMetadataTable) {
	constructor(dynamoDbClient) {
		super(
			'AccessTokenMetadata',
			dynamoDbClient 
		);
	}
}

export default new DIFactory(AccessTokenMetadataTable, [AWS.DynamoDB.DocumentClient]);
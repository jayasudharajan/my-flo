import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import TokenMetadataTable from './TokenMetadataTable';
import ValidationMixin from '../../models/ValidationMixin'
import TRefreshTokenMetadata from './models/TRefreshTokenMetadata';


class RefreshTokenMetadataTable extends ValidationMixin(TRefreshTokenMetadata, TokenMetadataTable) {
	constructor(dynamoDbClient) {
		super(
			'RefreshTokenMetadata',
			dynamoDbClient 
		);
	}

	marshal({ client_id, user_id, ...data }) {
		return super.marshal({
			...data,
			user_id,
			client_id,
			user_id_client_id: `${ user_id }_${ client_id }`
		});
	}

	retrieveByAccessTokenId(accessTokenId) {
		return this.dynamoDbClient.query({
			TableName: this.tableName,
			IndexName: 'AccessTokenIdIndex',
			KeyConditionExpression: 'access_token_id = :access_token_id',
			ExpressionAttributeValues: {
				':access_token_id': accessTokenId
			},
			Limit: 1
		})
		.promise();
	}

	removeByAccessTokenId(accessTokenId) {
		return this.retrieveByAccessTokenId(accessTokenId)
			.then(({ Items }) => 
				Promise.all(
					Items.map(item => this.remove(_.pick(item, ['token_id'])))
				)
			);
	}

	updateExpirationByAccessTokenId(accessTokenId, expiresAt) {
		return this.retrieveByAccessTokenId(accessTokenId)
			.then(({ Items }) => 
				Promise.all(
					Items.map(({ token_id, expires_at }) => 
						expires_at > expiresAt && this.patch({ token_id }, { expires_at: expiresAt })
					)
				)
			);
	}

	retrieveLatestByUserId(user_id, limit = 5) {
		return this.dynamoDbClient.query({
			TableName: this.tableName,
			IndexName: 'UserIdCreatedAtIndex',
			KeyConditionExpression: 'user_id = :user_id',
			Limit: limit,
			ScanIndexForward: false,
			ExpressionAttributeValues: {
				':user_id': user_id
			}
		})
		.promise()
		.then(({ Items }) => Items);
	}

	retrieveLatestByUserIdClientId(user_id, client_id, limit = 5) {
		return this.dynamoDbClient.query({
			TableName: this.tableName,
			IndexName: 'UserIdClientIdCreatedAtIndex',
			KeyConditionExpression: 'user_id_client_id = :user_id_client_id',
			Limit: limit,
			ScanIndexForward: false,
			ExpressionAttributeValues: {
				':user_id_client_id': `${ user_id }_${ client_id }`
			}
		})
		.promise()
		.then(({ Items }) => Items);
	}
}

export default new DIFactory(RefreshTokenMetadataTable, [AWS.DynamoDB.DocumentClient]);
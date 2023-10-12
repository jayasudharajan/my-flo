import _ from 'lodash';
import uuid from 'uuid';
import AWS from 'aws-sdk';
import EncryptedDynamoTable from '../../models/EncryptedDynamoTable';
import moment from 'moment';
import DIFactory from  '../../../util/DIFactory';
import ValidationMixin from '../../models/ValidationMixin'
import EncryptionStrategy from '../utils/EncryptionStrategy';
import TUserRegistrationTokenMetadata from './models/TUserRegistrationTokenMetadata';
import { hmac } from '../../../util/encryption';

class UserRegistrationTokenMetadataTable extends ValidationMixin(TUserRegistrationTokenMetadata, EncryptedDynamoTable) {
	constructor(dynamoDbClient, encryptionStrategy) {
		super('UserRegistrationTokenMetadata', 'token_id', undefined, ['registration_data'], dynamoDbClient, encryptionStrategy);
	}

	retrieveLatestUnexpiredByEmail(email) {
		return this.decryptQuery(
			this.dynamoDbClient.query({
				TableName: this.tableName,
				IndexName: 'EmailHashIndex',
				KeyConditionExpression: 'email_hash = :email_hash',
				FilterExpression: 'registration_data_expires_at > :now',
				Limit: 1,
				ScanIndexForward: false,
				ExpressionAttributeValues: {
					':email_hash': hmac(email),
					':now': new Date().toISOString()
				}
			})
			.promise()
		)
		.then(({ Items: [ metadata ] }) => {

			if (_.isEmpty(metadata)) {
				return metadata;
			}

			return this.unmarshal(metadata);
		});
	}

	retrieve(keys) {
		return super.retrieve(keys)
			.then(result => {
				return {
					...result,
					Item: this.unmarshal(result.Item)
				};
			});
	}

	marshal(data = {}) {
		const registrationData = !data.registration_data ?
			{} :
			{ registration_data: JSON.stringify(data.registration_data) };
		const sanitizedEmail = data.email && data.email.toLowerCase().trim();
		const emailHash = !sanitizedEmail ?
			{} :
			{ email_hash: hmac(sanitizedEmail) };
		const registrationDataExpiresAt = !data.registration_data_expires_at ?
			{} : 
			{ _registration_data_expires_at_secs: moment(data.registration_data_expires_at).unix() };
		const tokenData = _.omit(data, ['email', 'registration_data']);

		return super.marshal({
			...tokenData,
			...registrationData,
			...emailHash,
			...registrationDataExpiresAt
		});
	}

	unmarshal(data = {}) {
		const registrationData = !data.registration_data ?
			{} : 
			{ registration_data: JSON.parse(data.registration_data) };

		return {
			...data,
			...registrationData
		};
	}
}

export default new DIFactory(UserRegistrationTokenMetadataTable, [AWS.DynamoDB.DocumentClient, EncryptionStrategy]);
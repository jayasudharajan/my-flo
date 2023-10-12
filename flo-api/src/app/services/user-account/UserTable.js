import _ from 'lodash';
import uuid from 'uuid';
import AWS from 'aws-sdk';
import { createSalt, hashPwd , hmac } from '../../../util/encryption';
import EmailAlreadyInUseException from './models/exceptions/EmailAlreadyInUseException';
import TUser from './models/TUser';
import DIFactory from  '../../../util/DIFactory';
import EncryptedDynamoTable from '../../models/EncryptedDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import EncryptionStrategy from '../utils/EncryptionStrategy';

class UserTable extends EncryptedDynamoTable {
	constructor(dynamoDbClient, encryptionStrategy) {
		super('User', 'id',	undefined, ['email'], dynamoDbClient, encryptionStrategy);
	}

	_ensureUniqueEmail(userData) {
		return this._retrieveByEmail(userData.email, 1)
			.then(({ Items }) => {
				if (!Items.length || Items.some(({ id }) => id === userData.id)) {
					return userData;
				} else {
					return Promise.reject(new EmailAlreadyInUseException());
				}
			});
	}

	create(data, options) {
		const userData = processUserData({
			...data,
			id: data.id || uuid.v4()
		}, options);

		return this._ensureUniqueEmail(userData)
			.then(userData => super.create(userData));
	}

	update(data) {
		const userData = processUserData(data);

		return this._ensureUniqueEmail(userData)
			.then(userData => super.update(userData));
	}

	patch(keys, data) {
		const userData = processUserData(data);

		return (
			userData.email ? 
			this._ensureUniqueEmail({ ...userData, ...keys }) :
			Promise.resolve(userData)
		)
		.then(userData => super.patch(keys, userData))
	}

	_retrieveByEmail(email, limit) {
		const params = {
			TableName: this.tableName,
			IndexName: 'EmailIndex',
			KeyConditionExpression: 'email = :email',
			ExpressionAttributeValues: {
				':email': email.toLowerCase().trim()
			},
			Limit: limit
		};

		return this.decryptQuery(this.dynamoDbClient.query(params).promise());
	}

	retrieve(keys) {
		return super.retrieve(keys)
			.then(result => ({
				...result,
				Item: _.omit(result.Item, ['email_hash'])
			}));
	}

	marshal(data) {
		return super.marshal(_.omit(data, ['_is_ip_restricted']));
	}

	marshalPatch(keys, data) {
		return super.marshalPatch(keys, _.omit(data, ['_is_ip_restricted']));
	}
}

function processUserData(data, options) {
	const sanitizedEmail = data.email && data.email.toLowerCase().trim();
	const p_password = (data.password && (!options || !options.passwordHash)) ? hashPwd(createSalt(), data.password) : data.password
	return _.omitBy({
		...data,
		email: sanitizedEmail || undefined,
		password: p_password || undefined
	}, _.isUndefined);
}

class ValidatedUserTable extends ValidationMixin(TUser, UserTable) {

	retrieveByEmail(email) {
		return this._retrieveByEmail(email);
	}
}

export default new DIFactory(ValidatedUserTable, [AWS.DynamoDB.DocumentClient, EncryptionStrategy]);
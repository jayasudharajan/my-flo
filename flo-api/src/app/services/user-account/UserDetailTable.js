import AWS from 'aws-sdk';
import TUserDetail from './models/TUserDetail';
import DIFactory from  '../../../util/DIFactory';
import EncryptedDynamoTable from '../../models/EncryptedDynamoTable';
import ValidationMixin from '../../models/ValidationMixin'
import EncryptionStrategy from '../utils/EncryptionStrategy';

class UserDetailTable extends ValidationMixin(TUserDetail, EncryptedDynamoTable) {
	constructor(dynamoDbClient, encryptionStrategy) {
		super(
			'UserDetail',
			'user_id',	
			undefined, 
			['firstname', 'lastname', 'middlename', 'phone_mobile'],
			dynamoDbClient, 
			encryptionStrategy
		);
	}
}

export default new DIFactory(UserDetailTable, [AWS.DynamoDB.DocumentClient, EncryptionStrategy]);
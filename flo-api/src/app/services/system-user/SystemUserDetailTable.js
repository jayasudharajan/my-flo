import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import EncryptedDynamoTable from '../../models/EncryptedDynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import EncryptionStrategy from '../utils/EncryptionStrategy';

class SystemUserDetailTable extends EncryptedDynamoTable {

  constructor(dynamoDbClient, encryptionStrategy) {
    super('SystemUserDetail', 'user_id', undefined, ['roles', 'token_ttl'], dynamoDbClient, encryptionStrategy);
  }

  encryptProps(data) {
  	const props = _.clone(data);

  	if (data.roles) {
  		props.roles = JSON.stringify(data.roles);
  	} 

  	if (data.token_ttl) {
  		props.token_ttl = data.token_ttl + '';
  	}

  	return super.encryptProps(props);
  }

  decryptProps(data) {
  	return super.decryptProps(data)
  		.then(decryptedData => {
  			const props = _.clone(decryptedData);

  			if (decryptedData.roles) {
  				props.roles = JSON.parse(decryptedData.roles);
  			}

  			return props;
  		});
  }

}

export default new DIFactory(SystemUserDetailTable, [AWS.DynamoDB.DocumentClient, EncryptionStrategy]);
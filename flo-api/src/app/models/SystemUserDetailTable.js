import client from '../../util/dynamoUtil';
import _ from 'lodash';
import EncryptedDynamoTable from './EncryptedDynamoTable';

class SystemUserDetailTable extends EncryptedDynamoTable {

  constructor() {
    super('SystemUserDetail', 'user_id', undefined, ['roles', 'token_ttl']);
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

export default SystemUserDetailTable;
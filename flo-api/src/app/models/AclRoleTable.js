import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class AclRoleTable extends DynamoTable {

  constructor() {
    super('AclRole', 'role_id');
  }

}

export default AclRoleTable;
import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class SMSDeliveryLogTable extends DynamoTable {

  constructor() {
    super('SMSDeliveryLog', 'id');
  }

}

export default SMSDeliveryLogTable;
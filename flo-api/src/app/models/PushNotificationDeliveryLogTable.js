import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class PushNotificationDeliveryLogTable extends DynamoTable {

  constructor() {
    super('PushNotificationDeliveryLog', 'id');
  }

}

export default PushNotificationDeliveryLogTable;
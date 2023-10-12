import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class AppDeviceNotificationInfoTable extends DynamoTable {

  constructor() {
    super('AppDeviceNotificationInfo', 'id');
  }

  retrieveByUserIdICDId(keys) {
    let indexName = "UserIdICDIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: "user_id = :user_id AND icd_id = :icd_id",
      ExpressionAttributeValues: {
        ":user_id": keys.user_id,
        ":icd_id": keys.icd_id,
        ":is_deleted": false
      },
      FilterExpression: "is_deleted = :is_deleted OR attribute_not_exists(is_deleted)"
    };

    return client.query(params).promise();
  }

}

export default AppDeviceNotificationInfoTable;
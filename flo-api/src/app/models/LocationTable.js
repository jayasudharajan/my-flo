import client from '../../util/dynamoUtil';
import _ from 'lodash';
import EncryptedDynamoTable from './EncryptedDynamoTable';

class LocationTable extends EncryptedDynamoTable {

  constructor() {
    super('Location', 'account_id', 'location_id', [
      "address",
      "address2",
      "city",
      "country",
      "location_type",
      "postalcode",
      "state",
      "timezone"
      ]);
  }

  create(data) {
    return super.create({
      ...data,
      gallons_per_day_goal: 240
    });
  }

  update(data) {
    return super.update({
      ...data,
      gallons_per_day_goal: 240
    });
  }

  retrieveByAccountId(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'account_id = :account_id',
      ExpressionAttributeValues: {
        ':account_id': keys.account_id
      }
    };
    return this.decryptQuery(client.query(params).promise());
  }

  retrieveByLocationId(keys) {
    let indexName = 'LocationIdIndex';
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'location_id = :location_id',
      ExpressionAttributeValues: {
        ':location_id': keys.location_id
      }
    };
    return this.decryptQuery(client.query(params).promise());
  }

}

export default LocationTable;
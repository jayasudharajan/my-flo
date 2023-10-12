import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class TimeZoneTable extends DynamoTable {

  constructor() {
    super('TimeZone', 'tz');
  }

  // TODO: change this from being a scan and instead do query with GSI.
  retrieveActive() {

    let filter_expression = "is_active = :is_active";

    let params = {
      TableName: this.tableName,
      FilterExpression: filter_expression,
      ExpressionAttributeValues: {
          ":is_active": true
      }
    };

    // Order by abbreviation.
    return client.scan(params).promise()
      .then(result => {
        let timezones = _.orderBy(result.Items, ['name']);
        return new Promise((resolve, reject) => {
          resolve(timezones)
        });
      });

  }


}

export default TimeZoneTable;

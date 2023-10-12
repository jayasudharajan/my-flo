import client from '../../util/dynamoUtil';
import _ from 'lodash';
import DynamoTable from './DynamoTable';

class ICDAlarmIncidentRegistryTable extends DynamoTable {

  constructor() {
    super('ICDAlarmIncidentRegistry', 'id');
  }

  retrieveByICDId(keys, limit, startKeys) {
    let indexName = "ICDIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: { 
        ':icd_id': keys.icd_id
      }
    }
    if(!_.isUndefined(limit)) params.Limit = limit;
    if(!_.isUndefined(startKeys) && !_.isEmpty(startKeys)) {
        params.ExclusiveStartKey = { ...startKeys, icd_id: keys.icd_id };
    }

    return client.query(params).promise()
      .then((result) => {
        if(!_.isEmpty(result.Items)) {
          return new Promise((resolve, reject) => {
            // Sort by most recent first.
            result.Items = _.orderBy(result.Items, ['created_at'], ['desc']);
            resolve(result);
          });
        } else {
          return new Promise((resolve, reject) => {
            resolve(result)
          });
        }
      });

  }

  retrieveNewestByICDId(keys, limit, cursor) {
    let indexName = "ICDIdIncidentTimeIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      },
      ScanIndexForward: false
    }

    if(limit) params.Limit = limit;
    if(!_.isEmpty(cursor)) {
      params.ExclusiveStartKey = cursor;
    }
    return client.query(params).promise();
  }

  retrieveByICDIdIncidentTime(keys, limit, id) {
    let indexName = "ICDIdIncidentTimeIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id',
      ExpressionAttributeValues: {
        ':icd_id': keys.icd_id
      },
      ScanIndexForward: false,
      Limit: limit
    }

    if(id) {
      return this.retrieve({ id })
        .then(({ Item }) => {
          if(!Item) {
            return new Promise((resolve, reject) => {
              reject({ status: 404, message: "Item not found."})
            });
          } else {
            return client.query({
              ExclusiveStartKey: {
                id,
                icd_id: Item.icd_id,
                incident_time: Item.incident_time
              },
              ...params
            }).promise();
          }
        });
    } else {
      return client.query(params).promise();
    }
  }

  // FUTURE TODO(?): minimize which values are returned.
  //  id
  //  alarm_name
  //  incident_time / created_at
  //  severity
  retrieveUnacknowledgedByICDId(keys) {
    let indexName = "ICDIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id AND acknowledged_by_user = :acknowledged_by_user',
      ExpressionAttributeValues: { 
        ':icd_id': keys.icd_id,
        ':acknowledged_by_user': 0
      }
    }

    return client.query(params).promise()
      .then((result) => {
        if(!_.isEmpty(result.Items)) {
          return new Promise((resolve, reject) => {
            // Sort by most recent first.
            result.Items = _.orderBy(result.Items, ['created_at'], ['desc']);
            resolve(result);
          });
        } else {
          return new Promise((resolve, reject) => {
            //reject({ statusCode: 404, message: 'No items found.' })
            resolve(result)
          });
        }
      });

  }

  retrieveUnacknowledgedByICDIdAlarmIdSystemMode({ icd_id, alarm_id, system_mode }, ExclusiveStartKey) {
    const IndexName = 'ICDIdIndex';
    const params = {
      TableName: this.tableName,
      IndexName,
      ExclusiveStartKey,
      KeyConditionExpression: 'icd_id = :icd_id AND acknowledged_by_user = :acknowledged_by_user',
      FilterExpression: 'alarm_id = :alarm_id AND icd_data.system_mode = :system_mode',
      ExpressionAttributeValues: {
        ':icd_id': icd_id,
        ':acknowledged_by_user': 0,
        ':alarm_id': alarm_id,
        ':system_mode': system_mode
      }
    };

    return client.query(params).promise();
  }

  retrieveAcknowledgedByICDId({ icd_id, offset, descending }) {
    let indexName = "ICDIdIncidentTimeIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id',
      FilterExpression: 'acknowledged_by_user = :acknowledged_by_user',
      ExpressionAttributeValues: { 
        ':icd_id': icd_id,
        ':acknowledged_by_user': 1
      },
      ExclusiveStartKey: offset || undefined,
      ScanIndexForward: !descending
    }

    return client.query(params).promise();
  }

  retrieveHighestSeverityByICDId(keys) {
    let indexName = "ICDIdIndex";
    let params = {
      TableName: this.tableName,
      IndexName: indexName,
      KeyConditionExpression: 'icd_id = :icd_id AND acknowledged_by_user = :acknowledged_by_user',
      ExpressionAttributeValues: { 
        ':icd_id': keys.icd_id,
        ':acknowledged_by_user': 0
      }
    }

    return client.query(params).promise()
      .then((result) => {
        if(!_.isEmpty(result.Items)) {

          return new Promise((resolve, reject) => {
            // Get the top (most severe, recent) item.
            result.Items = _.orderBy(result.Items, ['created_at'], ['desc']);
            resolve(result);
          });
        } else {
          return new Promise((resolve, reject) => {
            //reject({ statusCode: 404, message: 'No items found.' })
            resolve(result)
          });
        }
      });

  }

  setAcknowledgedByICDIdAlarmIdSystemMode({ icd_id, alarm_id, system_mode }) {
    const ICDAlarmIncidentRegistry = this;

    return ICDAlarmIncidentRegistry.retrieveUnacknowledgedByICDIdAlarmIdSystemMode({ icd_id, alarm_id, system_mode })
      .then(pageResults);

    function pageResults({ Items, LastEvaluatedKey }) {
      const promises = Items.map(({ id }) => ICDAlarmIncidentRegistry.patch({ id }, { acknowledged_by_user: 1 }));

      if (LastEvaluatedKey) {
        return Promise.all([
            ...promises,
            ICDAlarmIncidentRegistry.retrieveUnacknowledgedByICDIdAlarmIdSystemMode({ icd_id, alarm_id, system_mode }, LastEvaluatedKey)
              .then(pageResults)
        ]);
      } else {
        return Promise.all(promises);
      }
    }
  }

  setAcknowledgedByICDId(keys) {
    let promises = [];
    
    return this.retrieveUnacknowledgedByICDId(keys)
      .then((result) => {

        // 'Acknowlege' (clear) all current known incidents.
        for(let item of result.Items) {
          promises.push(this.patch({ id: item.id }, { acknowledged_by_user: 1 }));
        }
        return Promise.all(promises);
      });

  }

}

export default ICDAlarmIncidentRegistryTable;

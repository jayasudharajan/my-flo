import VersionTable from './VersionTable';

class KernelVersionTable extends VersionTable {

  constructor() {
    super('KernelVersion');
  }

  retrieveByModel(keys) {
    let params = {
      TableName: this.tableName,
      KeyConditionExpression: 'model = :model',
      ExpressionAttributeValues: {
        ':model': keys.model
      }
    };
    return client.query(params).promise();
  }
  
}

export default KernelVersionTable;
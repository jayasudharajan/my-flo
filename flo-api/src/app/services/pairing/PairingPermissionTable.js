import AWS from 'aws-sdk';
import t from 'tcomb-validation';
import tcustom from '../../models/definitions/CustomTypes';
import DynamoTable from '../../models/DynamoTable';
import DIFactory from  '../../../util/DIFactory';
import { ValidationMixin, validateMethod } from '../../models/ValidationMixin';
import TPairingPermission from './models/TPairingPermission';


class PairingPermissionTable extends ValidationMixin(TPairingPermission, DynamoTable) {

  constructor(dynamoDbClient) {
    super('PairingPermission', 'user_id', 'created_at', dynamoDbClient);
  }

  retrieveByUserId(keys) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id
      }
    };
    return this._query(params);
  }

  retrieveLatestByUserId(keys) {
    const params = {
      TableName: this.tableName,
      KeyConditionExpression: 'user_id = :user_id',
      ExpressionAttributeValues: {
        ':user_id': keys.user_id
      },
      ScanIndexForward: false,
      Limit: 1
    };
    return this._query(params);
  }

}

validateMethod(
  PairingPermissionTable.prototype,
  'retrieveByUserId',
  [t.struct({ user_id: tcustom.UUIDv4 })]
);

validateMethod(
  PairingPermissionTable.prototype,
  'retrieveLatestByUserId',
  [t.struct({ user_id: tcustom.UUIDv4 })]
);

export default new DIFactory(PairingPermissionTable, [AWS.DynamoDB.DocumentClient]);
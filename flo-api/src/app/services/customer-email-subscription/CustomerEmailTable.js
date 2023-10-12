import _ from 'lodash';
import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TimestampMixin from '../../models/TimestampMixin';
import TCustomerEmail from './models/TCustomerEmail';


class CustomerEmailTable extends TimestampMixin(ValidationMixin(TCustomerEmail, DynamoTable)) {

  constructor(dynamoDbClient) {
    super('CustomerEmail', 'email_id', undefined, dynamoDbClient);
  }

  retrieveAll() {
    return this._withExhaustivePaging(
      ExclusiveStartKey => 
        this.dynamoDbClient.scan({
          TableName: this.tableName,
          ExclusiveStartKey
        })
        .promise()
    );
  }
}

export default new DIFactory(CustomerEmailTable, [AWS.DynamoDB.DocumentClient]);
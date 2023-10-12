import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import DynamoTable from '../../models/DynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TMultifactorAuthenticationTokenMetadata from './models/TMultifactorAuthenticationTokenMetadata';
import EncryptionStrategy from '../utils/EncryptionStrategy';

class MultifactorAuthenticationTokenMetadataTable
  extends ValidationMixin(TMultifactorAuthenticationTokenMetadata, DynamoTable) {

  constructor(dynamoDbClient) {
    super(
      'MultifactorAuthenticationTokenMetadata',
      'token_id',
      undefined,
      dynamoDbClient
    );
  }
}

export default new DIFactory(MultifactorAuthenticationTokenMetadataTable, [AWS.DynamoDB.DocumentClient]);
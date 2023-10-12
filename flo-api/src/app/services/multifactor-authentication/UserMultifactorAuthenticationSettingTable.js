import AWS from 'aws-sdk';
import DIFactory from  '../../../util/DIFactory';
import EncryptedDynamoTable from '../../models/EncryptedDynamoTable';
import ValidationMixin from '../../models/ValidationMixin';
import TMultifactorAuthenticationMetadata from './models/TMultifactorAuthenticationMetadata';
import EncryptionStrategy from '../utils/EncryptionStrategy';

class UserMultifactorAuthenticationSettingTable
  extends ValidationMixin(TMultifactorAuthenticationMetadata, EncryptedDynamoTable) {

  constructor(dynamoDbClient, encryptionStrategy) {
    super(
      'UserMultifactorAuthenticationSetting',
      'user_id',
      undefined,
      ['secret', 'otp_auth_url', 'qr_code_data_url'],
      dynamoDbClient,
      encryptionStrategy
    );
  }
}

export default new DIFactory(UserMultifactorAuthenticationSettingTable, [AWS.DynamoDB.DocumentClient, EncryptionStrategy]);
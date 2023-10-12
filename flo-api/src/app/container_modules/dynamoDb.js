import AWS from 'aws-sdk';
import EncryptionStrategy from '../services/utils/EncryptionStrategy';
import DynamoEncryptionStrategy from '../services/utils/DynamoEncryptionStrategy';
import config from '../../config/config';
import { ContainerModule } from 'inversify';

export default new ContainerModule(bind => {
  const dynamoDbOptions = {
    region: config.aws.dynamodb.region,
    endpoint: config.aws.dynamodb.endpoint,
    apiVersion: config.aws.apiVersion,
    httpOptions: {
      timeout: config.aws.timeoutMs
    }
  };
  const encryptionKeyId = config.encryption.dynamodb.keyId;
  const encryptionOptions = {
    bucketRegion: config.encryption.bucketRegion,
    bucketName: config.encryption.bucketName,
    keyPathTemplate: config.encryption.dynamodb.keyPathTemplate
  };

  const dynamoDbClient = new AWS.DynamoDB.DocumentClient(dynamoDbOptions);
  const dynamoEncryptionStrategy = new DynamoEncryptionStrategy(encryptionKeyId, encryptionOptions);

  bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
  bind(EncryptionStrategy).toConstantValue(dynamoEncryptionStrategy);
});
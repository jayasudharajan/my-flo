import { Container, ContainerModule } from 'inversify';
import EncryptionStrategy from '../utils/EncryptionStrategy';
import DynamoEncryptionStrategy from '../utils/DynamoEncryptionStrategy';
import SystemUserDetailTable from './SystemUserDetailTable';
import SystemUserService from './SystemUserService';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';

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

const container = new Container();
container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(EncryptionStrategy).toConstantValue(dynamoEncryptionStrategy);

export const containerModule = new ContainerModule(bind => {
  bind(SystemUserDetailTable).to(SystemUserDetailTable);
  bind(SystemUserService).to(SystemUserService);
});

container.load(containerModule);

export default container;
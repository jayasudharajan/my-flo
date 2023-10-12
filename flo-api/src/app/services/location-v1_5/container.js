import LocationTable from './LocationTable';
import LocationService from './LocationService';
import LocationController from './LocationController';
import EncryptionStrategy from '../utils/EncryptionStrategy';
import DynamoEncryptionStrategy from '../utils/DynamoEncryptionStrategy';
import AWS from 'aws-sdk';
import { Container, ContainerModule } from 'inversify';
import accountContainer from '../account-v1_5/container';
import authorizationContainer from '../authorization/container';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import containerUtils from '../../../util/containerUtil';

// Declare bindings
const container = new Container();

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

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(EncryptionStrategy).toConstantValue(dynamoEncryptionStrategy);

export const containerModule = new ContainerModule(bind => {
  bind(LocationTable).to(LocationTable);
  bind(LocationService).to(LocationService);
  bind(LocationController).to(LocationController);
});

container.load(containerModule);

export default [authorizationContainer, accountContainer].reduce(containerUtils.mergeContainers, container);

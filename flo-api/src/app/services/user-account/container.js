import authorizationContainer from '../authorization/container';
import locationContainer from '../location-v1_5/container';
import accountContainer from '../account-v1_5/container';
import UserTable from './UserTable';
import UserDetailTable from './UserDetailTable';
import UserAccountService from './UserAccountService';
import UserAccountController from './UserAccountController';
import UserAccountRouter from './routes';
import ACLMiddleware from '../utils/ACLMiddleware'
import EncryptionStrategy from '../utils/EncryptionStrategy';
import DynamoEncryptionStrategy from '../utils/DynamoEncryptionStrategy';
import AWS from 'aws-sdk';
import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import containerUtils from '../../../util/containerUtil';
import RouterDIFactory from '../../../util/RouterDIFactory';

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
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());

export const containerModule = new ContainerModule(bind => {
  bind(UserTable).to(UserTable);
  bind(UserDetailTable).to(UserDetailTable);
  bind(UserAccountService).to(UserAccountService);
  bind(UserAccountController).to(UserAccountController);
  bind(UserAccountRouter).to(UserAccountRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/useraccounts/', container => container.get(UserAccountRouter).router));
});

container.load(containerModule);

export default [authorizationContainer, locationContainer, accountContainer].reduce(containerUtils.mergeContainers, container);

import userAccountContainer from '../user-account/container';
import locationContainer from '../location-v1_5/container';
import legacyAuthContainer from '../legacy-auth/container';
import oauth2Container from '../oauth2/container';
import UserRegistrationTokenMetadataTable from './UserRegistrationTokenMetadataTable';
import UserRegistrationService from './UserRegistrationService';
import UserRegistrationController from './UserRegistrationController';
import UserRegistrationRouter from './routes';
import UserRegistrationConfig from './UserRegistrationConfig';
import EmailClient from '../utils/EmailClient';
import EmailClientConfig from '../utils/EmailClientConfig';
import EncryptionStrategy from '../utils/EncryptionStrategy';
import DynamoEncryptionStrategy from '../utils/DynamoEncryptionStrategy';
import ACLMiddleware from '../utils/ACLMiddleware';
import AuthMiddleware from '../utils/AuthMiddleware'
import AWS from 'aws-sdk';
import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import { mergeContainers } from '../../../util/containerUtil';

const dynamoDbOptions = {
  region: config.aws.dynamodb.region,
  endpoint: config.aws.dynamodb.endpoint,
  apiVersion: config.aws.apiVersion,
  httpOptions: {
    timeout: config.aws.timeoutMs
  }
};
const dynamoDbClient = new AWS.DynamoDB.DocumentClient(dynamoDbOptions);
const encryptionKeyId = config.encryption.dynamodb.keyId;
const encryptionOptions = {
	bucketRegion: config.encryption.bucketRegion,
	bucketName: config.encryption.bucketName,
	keyPathTemplate: config.encryption.dynamodb.keyPathTemplate
};
const dynamoEncryptionStrategy = new DynamoEncryptionStrategy(encryptionKeyId, encryptionOptions);

const container = new Container();

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(UserRegistrationTokenMetadataTable).to(UserRegistrationTokenMetadataTable);
container.bind(UserRegistrationService).to(UserRegistrationService);
container.bind(UserRegistrationController).to(UserRegistrationController);
container.bind(UserRegistrationRouter).to(UserRegistrationRouter);
container.bind(UserRegistrationConfig).toConstantValue(new UserRegistrationConfig(config));
container.bind(EmailClient).toConstantValue(new EmailClient(new EmailClientConfig(config)));
container.bind(EncryptionStrategy).toConstantValue(dynamoEncryptionStrategy);
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(AuthMiddleware).toConstantValue(new AuthMiddleware());

export default [
	userAccountContainer,
	locationContainer,
	legacyAuthContainer,
	oauth2Container
]
.reduce(mergeContainers, container);
import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import containerUtil from '../../../util/containerUtil';
import authorizationContainer from '../authorization/container';
import userAccountContainer from '../user-account/container';
import clientContainer from '../client/container';
import multifactorAuthenticationContiner from '../multifactor-authentication/container';
import UserLoginAttemptTable from './UserLoginAttemptTable';
import UserLockStatusTable from './UserLockStatusTable';
import AuthenticationService from './AuthenticationService';

const dynamoDbOptions = {
  region: config.aws.dynamodb.region,
  endpoint: config.aws.dynamodb.endpoint,
  apiVersion: config.aws.apiVersion,
  httpOptions: {
    timeout: config.aws.timeoutMs
  }
};
const dynamoDbClient = new AWS.DynamoDB.DocumentClient(dynamoDbOptions);

const container = new Container();

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);

export const containerModule = new ContainerModule(bind => {
  bind(UserLoginAttemptTable).to(UserLoginAttemptTable);
  bind(UserLockStatusTable).to(UserLockStatusTable);
  bind(AuthenticationService).to(AuthenticationService);  
});

container.load(containerModule);

export default [
	authorizationContainer,
	userAccountContainer,
	clientContainer,
	multifactorAuthenticationContiner
].reduce(containerUtil.mergeContainers, container);
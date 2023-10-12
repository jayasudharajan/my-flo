import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import containerUtil from '../../../util/containerUtil';
import userAccountContainer from '../user-account/container';
import legacyAuthContainer from '../legacy-auth/container';
import UserMultifactorAuthenticationSettingTable from './UserMultifactorAuthenticationSettingTable';
import MultifactorAuthenticationTokenMetadataTable from './MultifactorAuthenticationTokenMetadataTable';
import MultifactorAuthenticationService from './MultifactorAuthenticationService';
import MultifactorAuthenticationController from './MultifactorAuthenticationController';
import MultifactorAuthenticationRouter from './routes';
import MultifactorAuthenticationConfig from './MultifactorAuthenticationConfig';
import RouterDIFactory from '../../../util/RouterDIFactory';

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
  bind(MultifactorAuthenticationConfig).toConstantValue(new MultifactorAuthenticationConfig(config));
  bind(UserMultifactorAuthenticationSettingTable).to(UserMultifactorAuthenticationSettingTable);
  bind(MultifactorAuthenticationTokenMetadataTable).to(MultifactorAuthenticationTokenMetadataTable);
  bind(MultifactorAuthenticationService).to(MultifactorAuthenticationService);
  bind(MultifactorAuthenticationController).to(MultifactorAuthenticationController);
  bind(MultifactorAuthenticationRouter).to(MultifactorAuthenticationRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/mfa', container => container.get(MultifactorAuthenticationRouter).router));
});

container.load(containerModule);

export default [
  legacyAuthContainer,
  userAccountContainer
].reduce(containerUtil.mergeContainers, container);
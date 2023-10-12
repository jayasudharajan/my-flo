import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import containerUtil from '../../../util/containerUtil';
import authenticationContainer from '../authentication/container';
import authorizationContainer from '../authorization/container';
import userAccountContainer from '../user-account/container';
import clientContainer from '../client/container';
import AccessTokenMetadataTable from './AccessTokenMetadataTable';
import RefreshTokenMetadataTable from './RefreshTokenMetadataTable';
import AuthorizationCodeMetadataTable from './AuthorizationCodeMetadataTable';
import OAuth2Service from './OAuth2Service';
import OAuth2Controller from './OAuth2Controller';
import OAuth2Router from './routes';
import OAuth2Config from './OAuth2Config';
import ScopeTable from './ScopeTable';
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
  bind(AccessTokenMetadataTable).to(AccessTokenMetadataTable);
  bind(RefreshTokenMetadataTable).to(RefreshTokenMetadataTable);
  bind(AuthorizationCodeMetadataTable).to(AuthorizationCodeMetadataTable);
  bind(OAuth2Service).to(OAuth2Service);
  bind(OAuth2Controller).to(OAuth2Controller);
  bind(OAuth2Router).to(OAuth2Router);
  bind(OAuth2Config).toConstantValue(new OAuth2Config(config));
  bind(ScopeTable).to(ScopeTable);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/oauth2', container => container.get(OAuth2Router).router));
});

container.load(containerModule);
	
export default [
	authenticationContainer,
	authorizationContainer,
	userAccountContainer,
	clientContainer
].reduce(containerUtil.mergeContainers, container);
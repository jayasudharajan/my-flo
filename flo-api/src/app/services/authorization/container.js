import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import UserAccountGroupRoleTable from './UserAccountGroupRoleTable'
import UserAccountRoleTable from './UserAccountRoleTable';
import UserLocationRoleTable from './UserLocationRoleTable';
import UserSystemRoleTable from './UserSystemRoleTable';
import ACLService from '../utils/ACLService';
import * as aclUtils from '../../../util/aclUtils';
import AuthorizationService from './AuthorizationService';
import systemUserContainer from '../system-user/container';
import containerUtil from '../../../util/containerUtil';
import AccountGroupResourceStrategy from './resource-strategies/AccountGroupResourceStrategy';
import AccountResourceStrategy from './resource-strategies/AccountResourceStrategy';
import LocationResourceStrategy from './resource-strategies/LocationResourceStrategy';
import UserResourceStrategy from './resource-strategies/UserResourceStrategy';
import SystemResourceStrategy from './resource-strategies/SystemResourceStrategy';
import ResourceStrategyFactory from './resource-strategies/ResourceStrategyFactory';
import WaterflowResourceStrategy from './resource-strategies/WaterflowResourceStrategy';
import IFTTTResourceStrategy from './resource-strategies/IFTTTResourceStrategy';
import GoogleSmartHomeResourceStrategy from './resource-strategies/GoogleSmartHomeResourceStrategy';
import AuthorizationController from './AuthorizationController';
import AuthorizationRouter from './routes';
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

export const containerModule = new ContainerModule((bind, unbind, isBound, rebind) => { 

  if (!isBound(ACLService)) {
    bind(ACLService).toConstantValue(aclUtils);
  }

  bind(UserAccountGroupRoleTable).to(UserAccountGroupRoleTable);
  bind(UserLocationRoleTable).to(UserLocationRoleTable);
  bind(UserAccountRoleTable).to(UserAccountRoleTable);
  bind(UserSystemRoleTable).to(UserSystemRoleTable);
  bind(AuthorizationService).to(AuthorizationService);
  bind(AccountGroupResourceStrategy).to(AccountGroupResourceStrategy);
  bind(AccountResourceStrategy).to(AccountResourceStrategy);
  bind(LocationResourceStrategy).to(LocationResourceStrategy);
  bind(UserResourceStrategy).toConstantValue(new UserResourceStrategy());
  bind(SystemResourceStrategy).to(SystemResourceStrategy);
  bind(WaterflowResourceStrategy).to(WaterflowResourceStrategy);
  bind(IFTTTResourceStrategy).toConstantValue(new IFTTTResourceStrategy());
  bind(GoogleSmartHomeResourceStrategy).toConstantValue(new GoogleSmartHomeResourceStrategy());
  bind(ResourceStrategyFactory).to(ResourceStrategyFactory);
  bind(AuthorizationController).to(AuthorizationController);
  bind(AuthorizationRouter).to(AuthorizationRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/authorization', container => container.get(AuthorizationRouter).router));
});


container.load(containerModule);

export default containerUtil.mergeContainers(systemUserContainer, container);

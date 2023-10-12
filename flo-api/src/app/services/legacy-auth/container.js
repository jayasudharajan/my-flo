import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import redis from 'redis';
import {getClient} from '../../../util/cache';
import containerUtil from '../../../util/containerUtil';
import authenticationContainer from '../authentication/container';
import systemUserContainer from '../system-user/container';
import mfaContainer from '../multifactor-authentication/container';
import UserTokenTable from './UserTokenTable';
import LegacyAuthService from './LegacyAuthService';
import Logger from '../utils/Logger';

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
container.bind(redis.RedisClient).toConstantValue(getClient());
container.bind(Logger).toConstantValue(new Logger());


export const containerModule = new ContainerModule(bind => {
  bind(UserTokenTable).to(UserTokenTable);
  bind(LegacyAuthService).to(LegacyAuthService);
});

container.load(containerModule);

export default [
  authenticationContainer,
  systemUserContainer,
  mfaContainer
].reduce(containerUtil.mergeContainers, container);
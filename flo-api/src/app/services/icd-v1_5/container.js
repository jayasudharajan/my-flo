import ICDTable from './ICDTable';
import ICDService from './ICDService';
import ICDController from './ICDController';
import AWS from 'aws-sdk';
import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import redis from 'redis';
import { getClient } from '../../../util/cache';
import ICDRoutes from './routes';
import ACLMiddleware from '../utils/ACLMiddleware';
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

const dynamoDbClient = new AWS.DynamoDB.DocumentClient(dynamoDbOptions);

export const containerModule = new ContainerModule((bind, unbind, isBound) => {

  if (!isBound(ICDTable)) {
    bind(ICDTable).to(ICDTable);
  }

  if (!isBound(ICDService)) {
    bind(ICDService).to(ICDService);
  }

  bind(ICDController).to(ICDController);
  bind(ICDRoutes).to(ICDRoutes);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1_5/icds', container => container.get(ICDRoutes).router));
});

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(redis.RedisClient).toConstantValue(getClient());
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.load(containerModule);

export default container;
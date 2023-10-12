import DirectiveResponseTable from './DirectiveResponseTable';
import DirectiveResponseService from './DirectiveResponseService';
import DirectiveResponseController from './DirectiveResponseController';
import DirectiveResponseRouter from './routes'
import ICDService from '../icd/ICDService';
import ICDTable from '../../models/ICDTable';
import AWS from 'aws-sdk';
import { Container } from "inversify";
import config from '../../../config/config';
import redis from 'redis';
import { getClient } from '../../../util/cache';
import ACLMiddleware from '../utils/ACLMiddleware'
import reflect from 'reflect-metadata';

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

container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(redis.RedisClient).toConstantValue(getClient());
container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);

container.bind(ICDTable).to(ICDTable);
container.bind(ICDService).to(ICDService);
container.bind(DirectiveResponseTable).to(DirectiveResponseTable);
container.bind(DirectiveResponseService).to(DirectiveResponseService);
container.bind(DirectiveResponseController).to(DirectiveResponseController);
container.bind(DirectiveResponseRouter).to(DirectiveResponseRouter);

export default container;

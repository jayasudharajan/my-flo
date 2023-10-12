import ZITResultTable from './ZITResultTable';
import ZITResultService from './ZITResultService';
import ZITResultController from './ZITResultController';
import ICDService from '../icd/ICDService';
import ICDTable from '../../models/ICDTable';
import AWS from 'aws-sdk';
import { Container } from "inversify";
import config from '../../../config/config';
import redis from 'redis';
import { getClient } from '../../../util/cache';
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

container.bind(redis.RedisClient).toConstantValue(getClient());
container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(ZITResultTable).to(ZITResultTable);
container.bind(ZITResultService).to(ZITResultService);
container.bind(ZITResultController).to(ZITResultController);
container.bind(ICDService).to(ICDService);
container.bind(ICDTable).to(ICDTable);

export default container;
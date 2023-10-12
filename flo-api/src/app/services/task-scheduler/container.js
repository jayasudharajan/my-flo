import AWS from 'aws-sdk';
import { Container, ContainerModule } from 'inversify';
import TaskSchedulerService from './TaskSchedulerService';
import config from '../../../config/config';
import reflect from 'reflect-metadata';

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

  if (!isBound(TaskSchedulerService)) {
    bind(TaskSchedulerService).to(TaskSchedulerService);
  }
});

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.load(containerModule);

export default container;
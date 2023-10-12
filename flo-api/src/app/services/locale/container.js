import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import LocaleTable from './LocaleTable';
import LocaleService from './LocaleService';
import LocaleController from './LocaleController';
import LocaleRouter from './routes';
import AWS from 'aws-sdk';

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

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(LocaleTable).to(LocaleTable);
container.bind(LocaleService).to(LocaleService);
container.bind(LocaleController).to(LocaleController);
container.bind(LocaleRouter).to(LocaleRouter);


export default container;


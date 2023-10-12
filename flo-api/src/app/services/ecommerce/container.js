import EcommerceService from './EcommerceService';
import EcommerceController from './EcommerceController';
import EcommerceAuthMiddleware from './EcommerceAuthMiddleware';
import EcommerceServiceConfig from './EcommerceServiceConfig';
import EcommerceRouter from './routes'
import AWS from 'aws-sdk';
import { Container } from "inversify";
import config from '../../../config/config';
import EmailClient from '../utils/EmailClient';
import EmailClientConfig from '../utils/EmailClientConfig';
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

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(EcommerceServiceConfig).toConstantValue(new EcommerceServiceConfig(config));
container.bind(EmailClient).toConstantValue(new EmailClient(new EmailClientConfig(config)));
container.bind(EcommerceAuthMiddleware).toConstantValue(new EcommerceAuthMiddleware(config));

container.bind(EcommerceService).to(EcommerceService);
container.bind(EcommerceController).to(EcommerceController);
container.bind(EcommerceRouter).to(EcommerceRouter);

export default container;

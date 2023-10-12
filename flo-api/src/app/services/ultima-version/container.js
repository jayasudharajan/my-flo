import UltimaVersionTable from './UltimaVersionTable';
import UltimaVersionService from './UltimaVersionService';
import UltimaVersionController from './UltimaVersionController';
import AWS from 'aws-sdk';
import { Container } from "inversify";
import config from '../../../config/config';
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
container.bind(UltimaVersionTable).to(UltimaVersionTable);
container.bind(UltimaVersionService).to(UltimaVersionService);
container.bind(UltimaVersionController).to(UltimaVersionController);

export default container;
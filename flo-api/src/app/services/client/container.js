import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AWS from 'aws-sdk';
import containerUtil from '../../../util/containerUtil';
import ClientTable from './ClientTable';
import ClientUserTable from './ClientUserTable';
import ClientService from './ClientService';
import ClientController from './ClientController';
import ClientRouter from './routes';
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
  bind(ClientTable).to(ClientTable);
  bind(ClientUserTable).to(ClientUserTable);
  bind(ClientService).to(ClientService);
  bind(ClientController).to(ClientController);
  bind(ClientRouter).to(ClientRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/clients', container => container.get(ClientRouter).router));
});

container.load(containerModule);

export default container;
import AccountTable from './AccountTable';
import AccountService from './AccountService';
import AccountController from './AccountController';
import AWS from 'aws-sdk';
import { Container, ContainerModule } from 'inversify';
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

export const containerModule = new ContainerModule(bind => {
  bind(AccountTable).to(AccountTable);
  bind(AccountService).to(AccountService);
  bind(AccountController).to(AccountController);
});

container.load(containerModule);

export default container;

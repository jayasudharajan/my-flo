import UserTokenTable from '../../models/UserTokenTable';
import NotificationTokenTable from './NotificationTokenTable';
import NotificationTokenService from './NotificationTokenService';
import NotificationTokenController from './NotificationTokenController';
import NotificationRouter from './routes';
import AWS from 'aws-sdk';
import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import ACLMiddleware from '../utils/ACLMiddleware'

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

container.bind(UserTokenTable).to(UserTokenTable);
container.bind(NotificationTokenTable).to(NotificationTokenTable);
container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(NotificationTokenService).to(NotificationTokenService);
container.bind(NotificationTokenController).to(NotificationTokenController);
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(NotificationRouter).to(NotificationRouter);

export default container;
import AccountGroupAlarmNotificationDeliveryRuleTable from './AccountGroupAlarmNotificationDeliveryRuleTable';
import AccountGroupAlarmNotificationDeliveryRuleService from './AccountGroupAlarmNotificationDeliveryRuleService';
import AccountGroupAlarmNotificationDeliveryRuleController from './AccountGroupAlarmNotificationDeliveryRuleController';
import AWS from 'aws-sdk';
import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import AccountGroupAlarmNotificationDeliveryRuleRoutes from './routes';
import ACLMiddleware from '../utils/ACLMiddleware'

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
container.bind(AccountGroupAlarmNotificationDeliveryRuleTable).to(AccountGroupAlarmNotificationDeliveryRuleTable);
container.bind(AccountGroupAlarmNotificationDeliveryRuleService).to(AccountGroupAlarmNotificationDeliveryRuleService);
container.bind(AccountGroupAlarmNotificationDeliveryRuleController).to(AccountGroupAlarmNotificationDeliveryRuleController);
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(AccountGroupAlarmNotificationDeliveryRuleRoutes).to(AccountGroupAlarmNotificationDeliveryRuleRoutes); 

export default container;
import MicroLeakTestTimeService from './MicroLeakTestTimeService';
import MicroLeakTestTimeController from './MicroLeakTestTimeController';
import MicroLeakTestTimeTable from './MicroLeakTestTimeTable';
import DirectiveLogTable from '../../models/DirectiveLogTable';
import ICDTable from '../icd-v1_5/ICDTable';
import ICDService from '../icd-v1_5/ICDService';
import DirectiveService from '../directives/DirectiveService';
import DirectiveConfig from '../directives/DirectiveConfig';
import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import MicroLeakTestTimeRoutes from './routes';
import ACLMiddleware from '../utils/ACLMiddleware';
import KafkaProducer from '../utils/KafkaProducer';
import AWS from 'aws-sdk';
import redis from 'redis';
import { getClient } from '../../../util/cache';

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

const kafkaProducer = new KafkaProducer(
  config.kafkaHost,
  config.encryption.kafka.encryptionEnabled,
  config.kafkaTimeout
);

container.bind(redis.RedisClient).toConstantValue(getClient());
container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(KafkaProducer).toConstantValue(kafkaProducer);
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(DirectiveConfig).toConstantValue(new DirectiveConfig());

container.bind(ICDTable).to(ICDTable);
container.bind(DirectiveLogTable).to(DirectiveLogTable);
container.bind(ICDService).to(ICDService);
container.bind(DirectiveService).to(DirectiveService);
container.bind(MicroLeakTestTimeTable).to(MicroLeakTestTimeTable);
container.bind(MicroLeakTestTimeService).to(MicroLeakTestTimeService);
container.bind(MicroLeakTestTimeController).to(MicroLeakTestTimeController);
container.bind(MicroLeakTestTimeRoutes).to(MicroLeakTestTimeRoutes);

export default container;
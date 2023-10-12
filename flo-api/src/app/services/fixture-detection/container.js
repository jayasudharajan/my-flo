import FixtureDetectionService from './FixtureDetectionService';
import FixtureDetectionController from './FixtureDetectionController';
import FixtureDetectionLogTable from './FixtureDetectionLogTable';
import FixtureDetectionConfig from './FixtureDetectionConfig';
import FixtureDetectionRouter from './routes';
import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import ACLMiddleware from '../utils/ACLMiddleware';
import KafkaProducer from '../utils/KafkaProducer';
import ICDTable from '../icd-v1_5/ICDTable';
import ICDService from '../icd-v1_5/ICDService';
import redis from 'redis';
import { getClient } from '../../../util/cache';
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

const kafkaProducer = new KafkaProducer(
  config.kafkaHost,
  config.encryption.kafka.encryptionEnabled,
  config.kafkaTimeout
);

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(redis.RedisClient).toConstantValue(getClient());
container.bind(KafkaProducer).toConstantValue(kafkaProducer);
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(FixtureDetectionConfig).toConstantValue(new FixtureDetectionConfig(config));

container.bind(ICDTable).to(ICDTable);
container.bind(ICDService).to(ICDService);
container.bind(FixtureDetectionLogTable).to(FixtureDetectionLogTable);
container.bind(FixtureDetectionService).to(FixtureDetectionService);
container.bind(FixtureDetectionController).to(FixtureDetectionController);
container.bind(FixtureDetectionRouter).to(FixtureDetectionRouter);

export default container;
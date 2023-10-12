import DirectiveLogTable from '../../models/DirectiveLogTable';
import ICDTable from '../icd-v1_5/ICDTable';
import ICDService from '../icd-v1_5/ICDService';
import DirectiveService from './DirectiveService';
import DirectiveConfig from './DirectiveConfig';
import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
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

export const containerModule = new ContainerModule((bind, unbind, isBound) => {
  
  if (!isBound(DirectiveLogTable)) {
    bind(DirectiveLogTable).to(DirectiveLogTable);
  }

  if (!isBound(DirectiveService)) {
    bind(DirectiveService).to(DirectiveService);
  }

  if (!isBound(DirectiveConfig)) {
    bind(DirectiveConfig).toConstantValue(new DirectiveConfig());
  }
});

container.bind(redis.RedisClient).toConstantValue(getClient());
container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(KafkaProducer).toConstantValue(kafkaProducer);
container.bind(ICDTable).to(ICDTable);
container.bind(ICDService).to(ICDService);
container.load(containerModule);

export default container;
import { Container, ContainerModule } from 'inversify';
import icdContainer from '../icd-v1_5/container';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import { mergeContainers } from '../../../util/containerUtil';
import OnboardingService from './OnboardingService';
import OnboardingController from './OnboardingController';
import AuthMiddleware from '../utils/AuthMiddleware'
import ACLMiddleware from '../utils/ACLMiddleware'
import OnboardingRouter from './routes'
import OnboardingLogTable from './OnboardingLogTable';
import AWS from 'aws-sdk';
import KafkaProducer from '../utils/KafkaProducer';
import { publish } from '../../../util/mqttUtils';

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

const container = new Container();

container.bind(AuthMiddleware).toConstantValue(new AuthMiddleware());
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());

export const containerModule = new ContainerModule((bind, unbind, isBound) => {
  bind(OnboardingController).to(OnboardingController);
  bind(OnboardingService).to(OnboardingService);
  bind(OnboardingRouter).to(OnboardingRouter);
  bind(OnboardingLogTable).to(OnboardingLogTable);
  bind('MQTTClient').toConstantValue({
    publish: publish
  });

  if (!isBound('OnboardingServiceConfig')) {
    bind('OnboardingServiceConfig').toConstantValue(config);
  }

  if (!isBound(KafkaProducer)) {
    bind(KafkaProducer).toConstantValue(kafkaProducer);
  }
});

container.load(containerModule);

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);

export default [
	icdContainer
].reduce(mergeContainers, container);
import StockICDTable from './StockICDTable';
import StockICDService from './StockICDService';
import KafkaProducer from '../utils/KafkaProducer'
import StockICDController from './StockICDController';
import StockICDRouter from './routes';
import ACLMiddleware from '../utils/ACLMiddleware'
import AWS from 'aws-sdk';
import { Container, ContainerModule } from "inversify";
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import EncryptionStrategy from '../utils/EncryptionStrategy';
import DynamoEncryptionStrategy from '../utils/DynamoEncryptionStrategy';
import DeviceSerialNumberTable from './DeviceSerialNumberTable';
import DeviceSerialNumberCounterTable from './DeviceSerialNumberCounterTable';

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

const kafkaProducer = new KafkaProducer(
  config.kafkaHost,
  config.encryption.kafka.encryptionEnabled,
  config.kafkaTimeout
);

const encryptionKeyId = config.encryption.dynamodb.keyId;
const encryptionOptions = {
  bucketRegion: config.encryption.bucketRegion,
  bucketName: config.encryption.bucketName,
  keyPathTemplate: config.encryption.dynamodb.keyPathTemplate
};
const dynamoEncryptionStrategy = new DynamoEncryptionStrategy(encryptionKeyId, encryptionOptions);

container.bind(AWS.DynamoDB.DocumentClient).toConstantValue(dynamoDbClient);
container.bind(KafkaProducer).toConstantValue(kafkaProducer);
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(EncryptionStrategy).toConstantValue(dynamoEncryptionStrategy);

export const containerModule = new ContainerModule(bind => {

  bind(StockICDTable).to(StockICDTable);
  bind(StockICDService).to(StockICDService);
  bind(StockICDController).to(StockICDController);
  bind(StockICDRouter).to(StockICDRouter);
  bind(DeviceSerialNumberTable).to(DeviceSerialNumberTable);
  bind(DeviceSerialNumberCounterTable).to(DeviceSerialNumberCounterTable);  

});

container.load(containerModule);

export default container;
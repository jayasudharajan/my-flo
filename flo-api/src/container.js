import { Container } from 'inversify';
import reflect from 'reflect-metadata';
import Logger from './app/services/utils/Logger';
import _ from 'lodash';
import dynamoDbContainerModule from './app/container_modules/dynamoDb';
import middlewareContainerModule from './app/container_modules/middleware';
import redisContainerModule from './app/container_modules/redis';
import s3ContainerModule from './app/container_modules/s3';
import elasticsearchModule from './app/container_modules/elasticsearch';
import kafkaContainerModuler from './app/container_modules/kafka';
import postgresContainerModule from './app/container_modules/postgres';
import lambdaContainerModule from './app/container_modules/lambda';

import serviceContainerModules from './app/container_modules/services';

const container = new Container();

container.bind(Logger).toConstantValue(new Logger());

container.load(
  dynamoDbContainerModule, 
  redisContainerModule, 
  middlewareContainerModule,
  s3ContainerModule,
  elasticsearchModule,
  kafkaContainerModuler,
  postgresContainerModule,
  lambdaContainerModule,
  ...serviceContainerModules
);



export default container;
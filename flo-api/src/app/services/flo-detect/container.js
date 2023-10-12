import FloDetectService from './FloDetectService';
import FloDetectController from './FloDetectController';
import FloDetectResultTable from './FloDetectResultTable';
import FloDetectEventChronologyTable from './FloDetectEventChronologyTable';
import FloDetectFixtureAverageTable from './FloDetectFixtureAverageTable';
import FloDetectRouter from './routes';
import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import ACLMiddleware from '../utils/ACLMiddleware';
import ICDTable from '../icd-v1_5/ICDTable';
import ICDService from '../icd-v1_5/ICDService';
import redis from 'redis';
import { getClient } from '../../../util/cache';
import AWS from 'aws-sdk';
import RouterDIFactory from '../../../util/RouterDIFactory';

const container = new Container();

export const containerModule = new ContainerModule((bind, unbound, isBound) => {
  bind(FloDetectResultTable).to(FloDetectResultTable);
  bind(FloDetectEventChronologyTable).to(FloDetectEventChronologyTable);
  bind(FloDetectFixtureAverageTable).to(FloDetectFixtureAverageTable);
  bind(FloDetectService).to(FloDetectService);
  bind(FloDetectController).to(FloDetectController);
  bind(FloDetectRouter).to(FloDetectRouter);
  
  if (!isBound('FloDetectConfig')) {
    bind('FloDetectConfig').toConstantValue(config);
  }
  
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/flodetect', container => container.get(FloDetectRouter).router));

  if (!isBound(ICDTable)) {
    bind(ICDTable).to(ICDTable);
  }

  if (!isBound(ICDService)) {
    bind(ICDService).to(ICDService);
  }
});


export default container;
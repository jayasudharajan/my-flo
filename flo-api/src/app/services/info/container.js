import UsersIndex from './UsersIndex';
import ICDsIndex from './ICDsIndex';
import ActivityLogIndex from './ActivityLogIndex';
import InfoService from './InfoService';
import InfoController from './InfoController';
import elasticsearch from 'elasticsearch';
import { Container, ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import InfoRoutes from './routes';
import ACLMiddleware from '../utils/ACLMiddleware'
import RouterDIFactory from '../../../util/RouterDIFactory';

const elasticsearchClient = new elasticsearch.Client({
    host: config.elasticSearchHost
});
const container = new Container();

container.bind(elasticsearch.Client).toConstantValue(elasticsearchClient);
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());

export const containerModule = new ContainerModule(bind => {
  bind(UsersIndex).to(UsersIndex);
  bind(ICDsIndex).to(ICDsIndex);
  bind(ActivityLogIndex).to(ActivityLogIndex);
  bind(InfoService).to(InfoService);
  bind(InfoController).to(InfoController);
  bind(InfoRoutes).to(InfoRoutes);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/info', container => container.get(InfoRoutes).router));
});

container.load(containerModule);

export default container;
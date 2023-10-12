import elasticsearch from 'elasticsearch';
import { Container } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import InfoRoutes from './routes';
import AuthMiddleware from '../utils/AuthMiddleware'
import ACLMiddleware from '../utils/ACLMiddleware'
import ICDAlarmIncidentRegistriesIndex from './ICDAlarmIncidentRegistriesIndex';
import ICDAlarmIncidentRegistryLogsIndex from './ICDAlarmIncidentRegistryLogsIndex';
import AlarmController from './AlarmController';
import AlarmService from './AlarmService';
import AlarmRouter from './routes';

const elasticsearchClient = new elasticsearch.Client({
    host: config.elasticSearchHost
});

const container = new Container();

container.bind(ICDAlarmIncidentRegistriesIndex).to(ICDAlarmIncidentRegistriesIndex);
container.bind(ICDAlarmIncidentRegistryLogsIndex).to(ICDAlarmIncidentRegistryLogsIndex);
container.bind(AlarmService).to(AlarmService);
container.bind(AlarmController).to(AlarmController);
container.bind(AlarmRouter).to(AlarmRouter);
container.bind(AuthMiddleware).toConstantValue(new AuthMiddleware());
container.bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
container.bind(elasticsearch.Client).toConstantValue(elasticsearchClient);

export default container;

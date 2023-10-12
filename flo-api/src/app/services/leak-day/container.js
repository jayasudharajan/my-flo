import LeakDayService from './LeakDayService';
import LeakDayController from './LeakDayController';
import { ContainerModule } from 'inversify';
import config from '../../../config/config';
import reflect from 'reflect-metadata';
import LeakDayRoutes from './routes';
import ACLMiddleware from '../utils/ACLMiddleware'
import RouterDIFactory from '../../../util/RouterDIFactory';
import postgres from 'pg';

export const containerModule = new ContainerModule((bind, unbind, isBound) => {
  bind(LeakDayService).to(LeakDayService);
  bind(LeakDayController).to(LeakDayController);
  bind(LeakDayRoutes).to(LeakDayRoutes);
  bind('RouterFactory').toConstantValue(new RouterDIFactory(
    '/api/v1/leakdays', 
    container => {
      let postgresConnection = null;

      container.bind('PostgresClientProvider').toProvider(
        context => 
          onlyCached => {

            if (!postgresConnection && !onlyCached) {
              postgresConnection = container.get(postgres.Pool).connect();
            }

            return postgresConnection;
          }
      );

      return container.get(LeakDayRoutes).router;
    },
    container => {
      const postgresConnection = container.get('PostgresClientProvider')(true);

      if (postgresConnection) {
        postgresConnection
          .then(client => client.release());
      }
    }
  ));
});
import { ContainerModule } from 'inversify';
import postgres from 'pg';
import config from '../../config/config';

export default new ContainerModule(bind => {
  bind(postgres.Pool).toConstantValue(new postgres.Pool({
    user: config.postgresUser,
    host: config.postgresHost,
    database: config.postgresDatabase,
    password: config.postgresPassword,
    port: config.postgresPort
  }));
});
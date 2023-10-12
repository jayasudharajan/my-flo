import { ContainerModule } from 'inversify';
import AwayModeService from './AwayModeService';
import AwayModeController from './AwayModeController';
import AwayModeRouter from './routes';
import IrrigationScheduleService from './IrrigationScheduleService';
import RouterDIFactory from '../../../util/RouterDIFactory';
import AwayModeStateLogTable from './AwayModeStateLogTable';
import config from '../../../config/config';

export const containerModule = new ContainerModule((bind, unbind, isBound) => {
  bind(AwayModeService).to(AwayModeService);
  bind(AwayModeController).to(AwayModeController);
  bind(AwayModeRouter).to(AwayModeRouter);
  bind(IrrigationScheduleService).to(IrrigationScheduleService);
  bind(AwayModeStateLogTable).to(AwayModeStateLogTable);
  bind('AwayModeConfig').toConstantValue(config);

  bind('RouterFactory')
    .toConstantValue(new RouterDIFactory('/api/v1/awaymode/', container => container.get(AwayModeRouter).router));
});
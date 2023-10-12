import { ContainerModule } from 'inversify';
import DeviceSystemModeService from './DeviceSystemModeService';
import ICDForcedSystemModeTable from './ICDForcedSystemModeTable';
import DeviceSystemModeController from './DeviceSystemModeController';
import DeviceSystemModeRouter from './routes';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule((bind, unbound, isBound) => {

  bind(DeviceSystemModeService).to(DeviceSystemModeService);
  bind(ICDForcedSystemModeTable).to(ICDForcedSystemModeTable);
  bind(DeviceSystemModeController).to(DeviceSystemModeController);
  bind(DeviceSystemModeRouter).to(DeviceSystemModeRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/devicesystemmode', container => container.get(DeviceSystemModeRouter).router));
});
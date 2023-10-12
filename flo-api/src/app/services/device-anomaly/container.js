import {ContainerModule} from 'inversify';
import DeviceAnomalyEventTable from './DeviceAnomalyEventTable';
import DeviceAnomalyService from './DeviceAnomalyService';
import DeviceAnomalyController from './DeviceAnomalyController';
import DeviceAnomalyRouter from './routes';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule(bind => {
  bind(DeviceAnomalyEventTable).to(DeviceAnomalyEventTable);
  bind(DeviceAnomalyService).to(DeviceAnomalyService);
  bind(DeviceAnomalyController).to(DeviceAnomalyController);
  bind(DeviceAnomalyRouter).to(DeviceAnomalyRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/deviceanomalies', container => container.get(DeviceAnomalyRouter).router));
});
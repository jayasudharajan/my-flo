import { smarthome } from 'actions-on-google';
import { ContainerModule } from 'inversify';
import uuid from 'node-uuid';

import DeviceStateService from './DeviceStateService';
import DeviceStateController from './DeviceStateController';
import DeviceStateRouter from './routes';
import DeviceStateRequestLogTable from './DeviceStateLogTable';
import Logger from '../utils/Logger';
import RouterDIFactory from '../../../util/RouterDIFactory';
import config from '../../../config/config';

export const containerModule = new ContainerModule((bind, unbind, isBound) => {
  bind('DeviceStateConfig').toConstantValue(config);
  bind(DeviceStateRequestLogTable).to(DeviceStateRequestLogTable);
  bind(DeviceStateService).to(DeviceStateService);
  bind(DeviceStateController).to(DeviceStateController);
  bind(DeviceStateRouter).to(DeviceStateRouter);

  if (!isBound('SmartHome')) {
    bind('SmartHome').toConstantValue(smarthome);
  }

  if (!isBound('RandomUuid')) {
    bind('RandomUuid').toConstantValue(uuid.v4);
  }

  if (!isBound(Logger)) {
    bind(Logger).toConstantValue(new Logger());
  }

  bind('RouterFactory')
    .toConstantValue(
      new RouterDIFactory('/api/v1/device-state', container => container.get(DeviceStateRouter).router)
    );
});
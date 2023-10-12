import {ContainerModule} from 'inversify';
import FirmwareFeaturesService from './FirmwareFeaturesService';
import FirmwareFeaturesController from './FirmwareFeaturesController';
import FirmwareFeaturesRouter from './routes';
import config from '../../../config/config';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule(bind => {
  bind('FirmwareFeaturesConfig').toConstantValue(config);
  bind(FirmwareFeaturesService).to(FirmwareFeaturesService);
  bind(FirmwareFeaturesController).to(FirmwareFeaturesController);
  bind(FirmwareFeaturesRouter).to(FirmwareFeaturesRouter);
  bind('RouterFactory')
    .toConstantValue(
      new RouterDIFactory('/api/v1/firmware/features', container => container.get(FirmwareFeaturesRouter).router)
    );
});
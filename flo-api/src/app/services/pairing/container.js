import { ContainerModule } from 'inversify';
import PairingPermissionTable from './PairingPermissionTable';
import PairingService from './PairingService';
import PairingController from './PairingController';
import PairingRouter from './routes';
import RouterDIFactory from '../../../util/RouterDIFactory';
import * as pes from '../pes/pes';


export const containerModule = new ContainerModule((bind, unbound, isBound) => {
  bind(PairingService).to(PairingService);
  bind(PairingPermissionTable).to(PairingPermissionTable);
  bind(PairingController).to(PairingController);
  bind(PairingRouter).to(PairingRouter);
  bind('RouterFactory').toConstantValue(new RouterDIFactory('/api/v1/pairing', container => container.get(PairingRouter).router));

  if (!isBound('PESService')) {
    bind('PESService').toConstantValue(pes);
  }
});
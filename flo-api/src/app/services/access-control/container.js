import AccessControlTable from './AccessControlTable';
import AccessControlService from './AccessControlService';
import AccessControlController from './AccessControlController';
import AccessControlRouter from './routes';
import LocationProvider from './sub-resource-providers/LocationProvider';
import AccountProvider from './sub-resource-providers/AccountProvider';
import UserProvider from './sub-resource-providers/UserProvider';
import SubResourceProviderFactory from './sub-resource-providers/SubResourceProviderFactory';
import IFTTTProvider from './sub-resource-providers/IFTTTProvider';
import { ContainerModule } from 'inversify';
import RouterDIFactory from '../../../util/RouterDIFactory';

export const containerModule = new ContainerModule((bind, unbound, isBound) => {

  bind(AccessControlTable).to(AccessControlTable);
  bind(AccessControlService).to(AccessControlService);
  bind(AccessControlController).to(AccessControlController);
  bind(AccessControlRouter).to(AccessControlRouter);
  bind(LocationProvider).to(LocationProvider);
  bind(AccountProvider).to(AccountProvider);
  bind(IFTTTProvider).toConstantValue(new IFTTTProvider());
  bind(UserProvider).toConstantValue(new UserProvider());
  bind(SubResourceProviderFactory).to(SubResourceProviderFactory);

  bind('RouterFactory')
    .toConstantValue(new RouterDIFactory('/api/v1/accesscontrol/', container => container.get(AccessControlRouter).router));
});
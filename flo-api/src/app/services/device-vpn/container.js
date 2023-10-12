import VPNWhitelistTable from './VPNWhitelistTable';
import DeviceVPNService from './DeviceVPNService';
import DeviceVPNController from './DeviceVPNController';
import DeviceVPNRouter from './routes';
import DirectiveService from '../directives/DirectiveService';
import ICDService from '../icd-v1_5/ICDService';
import TaskSchedulerService from '../task-scheduler/TaskSchedulerService';
import RouterDIFactory from '../../../util/RouterDIFactory';
import { Container, ContainerModule } from 'inversify';
import reflect from 'reflect-metadata';
import FirebaseTokenRouter from "../firebase-token/routes";

const container = new Container();

export const containerModule = new ContainerModule((bind, unbound, isBound) => {

  bind(VPNWhitelistTable).to(VPNWhitelistTable);
  bind(DeviceVPNService).to(DeviceVPNService);
  bind(DeviceVPNController).to(DeviceVPNController);
  bind(DeviceVPNRouter).to(DeviceVPNRouter);

  bind('RouterFactory').toConstantValue(
    new RouterDIFactory('/api/v1/devicevpn', container => container.get(DeviceVPNRouter).router)
  );

  if (!isBound(DirectiveService)) {
    bind(DirectiveService).to(DirectiveService);
  }

  if (!isBound(ICDService)) {
    bind(ICDService).to(ICDService);
  }

  if (!isBound(ICDService)) {
    bind(TaskSchedulerService).to(TaskSchedulerService);
  }
});

container.load(containerModule);

export default container;
import AlertsIndex from './AlertsIndex';
import { ContainerModule } from 'inversify';

export const containerModule = new ContainerModule(bind => {
  bind(AlertsIndex).to(AlertsIndex);
});

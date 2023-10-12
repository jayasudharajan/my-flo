import AuthMiddleware from '../services/utils/AuthMiddleware';
import ACLMiddleware from '../services//utils/ACLMiddleware';
import { ContainerModule } from 'inversify';

export default new ContainerModule(bind => {
  bind(AuthMiddleware).to(AuthMiddleware);
  bind(ACLMiddleware).toConstantValue(new ACLMiddleware());
});

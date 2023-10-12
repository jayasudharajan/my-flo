import FirebaseAdminContainer from './FirebaseAdminContainer';
import FirebaseTokenService from './FirebaseTokenService';
import FirebaseTokenController from './FirebaseTokenController';
import FirebaseTokenRouter from './routes';
import { Container, ContainerModule } from 'inversify';
import ICDService from '../icd-v1_5/ICDService';
import RouterDIFactory from '../../../util/RouterDIFactory';
import InfoService from "../info/InfoService";

const container = new Container();

export const containerModule = new ContainerModule((bind, unbound, isBound) => {

  bind(FirebaseAdminContainer).to(FirebaseAdminContainer);
  bind(FirebaseTokenService).to(FirebaseTokenService);
  bind(FirebaseTokenController).to(FirebaseTokenController);
  bind(FirebaseTokenRouter).to(FirebaseTokenRouter);

  bind('RouterFactory').toConstantValue(
    new RouterDIFactory('/api/v1/firebase/token', container => container.get(FirebaseTokenRouter).router)
  );

  if (!isBound(InfoService)) {
    bind(InfoService).to(InfoService);
  }

  if (!isBound(ICDService)) {
    bind(ICDService).to(ICDService);
  }
});


export default container;
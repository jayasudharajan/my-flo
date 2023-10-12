import ZitResultRouter from '../services/zit-result/routes';
import AuthMiddleware from '../services/utils/AuthMiddleware';

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);
  app.use('/api/v1/zitresults', new ZitResultRouter(authMiddleware).routes());
}

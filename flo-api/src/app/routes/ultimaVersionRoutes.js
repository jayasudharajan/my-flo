import UltimaVersionRouter from '../services/ultima-version/routes';
import AuthMiddleware from '../services/utils/AuthMiddleware';

export default (app, appContainer) => {
  const authMiddleware = appContainer.get(AuthMiddleware);

  app.use('/api/v1/ultimaversions', new UltimaVersionRouter(authMiddleware).routes());
}
import express from 'express';
import { checkPermissions } from '../middleware/acl';
import StockICDRouter from '../services/stock-icd/routes';
import containerUtils from '../../util/containerUtil';
import stockICDContainer from '../services/stock-icd/container';
const stockICDController = require('../controllers/stockICDController');
import AuthMiddleware from '../services/utils/AuthMiddleware';

export default (app, container) => {
  const router = express.Router();
  const routesContainer = containerUtils.mergeContainers(stockICDContainer, container);
  const authMiddleware = container.get(AuthMiddleware);
  const stockICDRouter = routesContainer.get(StockICDRouter);
  const requiresPermission = checkPermissions('StockICD');

  // This is the one app using as of now
  router.route('/qrcode')
    .post(
      authMiddleware.requiresAuth({ addUserId: true, addLocationId: true }),
      requiresPermission('retrieveByQrCode'),
      stockICDController.retrieveByQrCode);

  router.use(stockICDRouter.routes());
  app.use('/api/v1/stockicds', router);
}




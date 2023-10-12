import express from 'express';
import EcommerceRouter from '../services/ecommerce/routes';
import containerUtils from '../../util/containerUtil';
import ecommerceContainer from '../services/ecommerce/container';

export default (app, container) => {
  const router = express.Router();
  const routesContainer = containerUtils.mergeContainers(ecommerceContainer, container);
  const ecommerceRouter = routesContainer.get(EcommerceRouter);

  router.use(ecommerceRouter.routes());
  app.use('/api/v1/ecommerce', router);
}

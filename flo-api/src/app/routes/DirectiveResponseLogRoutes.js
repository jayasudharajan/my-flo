import express from 'express';
import DirectiveResponseRouter from '../services/directive-response/routes';
import containerUtils from '../../util/containerUtil';
import directiveResponseContainer from '../services/directive-response/container';

export default (app, container) => {
  const router = express.Router();
  const routesContainer = containerUtils.mergeContainers(directiveResponseContainer, container);
  const directiveResponseRouter = routesContainer.get(DirectiveResponseRouter);

  router.use(directiveResponseRouter.routes());
  app.use('/api/v1/directiveresponselogs', router);
}

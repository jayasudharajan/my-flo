import MicroLeakTestTimeRouter from '../services/microleak-test-time/routes';
import containerUtils from '../../util/containerUtil';
import microLeakTestTimeRouterContainer from '../services/microleak-test-time/container';

export default (app, container) => {
  const routesContainer = containerUtils.mergeContainers(microLeakTestTimeRouterContainer, container);

  app.use('/api/v1/microleaktesttime', routesContainer.get(MicroLeakTestTimeRouter).router);
}
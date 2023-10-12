import FixtureDetectionRouter from '../services/fixture-detection/routes';
import containerUtils from '../../util/containerUtil';
import fixtureDetectionContainer from '../services/fixture-detection/container';

export default (app, container) => {
  const routesContainer = containerUtils.mergeContainers(fixtureDetectionContainer, container);

  app.use('/api/v1/fixtures/detection', routesContainer.get(FixtureDetectionRouter).router);
}
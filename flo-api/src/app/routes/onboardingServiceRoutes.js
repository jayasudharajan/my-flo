import express from 'express';
import OnboardingRouter from '../services/onboarding/routes';
import containerUtils from '../../util/containerUtil';
import onboardingContainer from '../services/onboarding/container';

export default (app, container) => {
  const router = express.Router();
  const routesContainer = containerUtils.mergeContainers(onboardingContainer, container);
  const onboardingRouter = routesContainer.get(OnboardingRouter);

  router.use(onboardingRouter.routes());
  app.use('/api/v1/onboarding', router);
}
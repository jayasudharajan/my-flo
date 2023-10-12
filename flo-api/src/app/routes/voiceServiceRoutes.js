import express from 'express';
import VoiceRouter from '../services/voice/routes';
import containerUtils from '../../util/containerUtil';
import voiceContainer from '../services/voice/container';

export default (app, container) => {
  const router = express.Router();
  const routesContainer = containerUtils.mergeContainers(voiceContainer, container);
  const voiceRouter = routesContainer.get(VoiceRouter);

  router.use(voiceRouter.routes());
  app.use('/api/v1/voice', router);
}
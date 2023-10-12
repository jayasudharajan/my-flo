var  express = require( 'express');
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';
import DirectiveRouter from '../services/directives/routes';

var directivesController = require('../controllers/directivesController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  const router = express.Router();
  const requiresPermission = checkPermissions('Directives');

  router.route('/tracking')
    .post(
      authMiddleware.requiresAuth(),
      //directivesValidators.track,
      requiresPermission('track'),
      directivesController.track);

  router.use(new DirectiveRouter(authMiddleware).routes());
  app.use('/api/v1/directives', router);
}


import express from 'express';
import AuthMiddleware from '../services/utils/AuthMiddleware';
import { checkPermissions } from '../middleware/acl';

let ICDOnlineStatusLogController = require('../controllers/ICDOnlineStatusLogController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ICDOnlineStatusLog');

  router.route('/device/:device_id/:status')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('logDeviceStatus'),
      ICDOnlineStatusLogController.logDeviceStatus
    );


  app.use('/api/v1/icdonlinestatuslogs', router);

}
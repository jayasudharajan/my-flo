import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let ICDForcedSystemModeController = require('../controllers/ICDForcedSystemModeController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('ICDForcedSystemMode');

  router.route('/:icd_id/latest')
    .get(
      authMiddleware.requiresAuth(),
      //ICDForcedSystemModeValidators.retrieveLatestByIcdId,
      requiresPermission('retrieveLatestByIcdId'),
      ICDForcedSystemModeController.retrieveLatestByIcdId
    );

  router.route('/device/:device_id/latest')
    .get(
      authMiddleware.requiresAuth(),
      requiresPermission('retrieveLatestByDeviceId'),
      ICDForcedSystemModeController.retrieveLatestByDeviceId
    );

  app.use('/api/v1/icdforcedsystemmodes', router);

}
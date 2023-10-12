import express from 'express';
import { checkPermissions } from '../middleware/acl';
import AuthMiddleware from '../services/utils/AuthMiddleware';

let PKILogController = require('../controllers/PKILogController');

export default (app, appContainer) => {

  const authMiddleware = appContainer.get(AuthMiddleware);
  let router = express.Router();
  let requiresPermission = checkPermissions('PKILog');

  // Create
  router.route('/')
    .post(
      authMiddleware.requiresAuth(),
      requiresPermission('create'),
      PKILogController.create
    );

  app.use('/api/v1/pkilogs', router);

}
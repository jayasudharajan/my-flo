import express from 'express';
import moment from 'moment';
import config from '../../config/config';

export default (app) => {
  const router = express.Router();

  router.route('/')
    .get((req, res) => {
      res.json({
        date: moment().utc().format(),
        app: config.appName,
        env: config.env
      });
    });

  app.use('/api/v1/ping', router);
}
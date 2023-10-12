/**
 * Created by Francisco on 1/27/2017.
 */
import express from 'express';
let appVersionController = require('../controllers/appVersionController');


export default (app) => {
    let router = express.Router();

    router.route('/apple/:version')
        .get(
            appVersionController.appleAppVersion
        );
    app.use('/api/v1/appversion', router);
}
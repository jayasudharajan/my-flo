/**
 * Created by Francisco on 1/27/2017.
 */
import _ from 'lodash';
import config from '../../config/config';


/**
 * This endpoint will deliver to mobile app client the latest version of the mobile app,
 * */

export function appleAppVersion(req, res, next) {
    const {version}  = req.params;
    const update = (
        config.notForceUpdateForMobileAppIosVersions.toLowerCase().split(',').indexOf(version.toLowerCase()) < 0 &&
        config.latestAppVersionIos.toLowerCase() !== version.toLowerCase()
    );
    const rVersion = update ? config.latestAppVersionIos : version;
    const redirectURL = update ? config.latestAppVersionAppStoreUrl : null;

    const response = {
        version: rVersion,
        force_update: update,
        redirect_url: redirectURL
    };
    res.json(response)
}




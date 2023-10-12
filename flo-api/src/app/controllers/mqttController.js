/**
 * Endpoints for Device Directives through MQTT.
 */
import ICDTable from '../models/ICDTable';
import PairingPermissionTable from '../services/pairing/PairingPermissionTable';
import { userRoles } from '../../util/aclUtils';
import moment from 'moment';
import directives from '../../util/directives';

var icd = new ICDTable();
var pairingPermission = new PairingPermissionTable();

export function toggleValve(req, res, next) {
    const { deviceid: device_id, valveaction, user_id } = req.params;

    directives(user_id, req.app_used, req.log).toggleValve({ device_id, valveaction })
        .then(() => res.send())
        .catch(err => next(err));
}


export function powerReset(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;

    directives(user_id, req.app_used, req.log).powerReset({ device_id })
        .then(() => res.send())
        .catch(err => next(err));
}

/** setSystemMode POST
 *  URL: api/v1/mqtt/client/setsystemmode/{device id}
 *  BODY: "systemmodeid": [mode id]
 */
export function setSystemMode(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;
    const { systemmodeid } = req.body;

    directives(user_id, req.app_used, req.log).setSystemMode({ device_id, systemmodeid })
        .then(() => res.send())
        .catch(err => next(err));
}

export function enableForcedSleep(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;

    directives(user_id, req.app_used, req.log).enableForcedSleep({ device_id })
        .then(() => res.send())
        .catch(err => next(err));
}

export function disableForcedSleep(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;

    directives(user_id, req.app_used, req.log).disableForcedSleep({ device_id })
        .then(() => res.send())
        .catch(err => next(err));
}

export function sleep(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;
    const systemmodeid = req.body.systemmodeid;
    const sleep_minutes = parseInt(req.body.sleep_minutes);

    directives(user_id, req.app_used, req.log).sleep({ device_id, systemmodeid, sleep_minutes })
        .then(() => res.send())
        .catch(err => next(err));
}

/** requestUpgrade POST
 * URL: api/v1/mqtt/client/requestupgrade/{device id}
 * BODY: "upgradetype": [upgrade-ultima/upgrade-kernel]
 *       "target": [agent-1/agent-2, default: agent-1]
 *       "url": [upgrade package url]
 *       "checksum": [upgrade package checksum]
 *       "alg": [checksum algrithm, default: sha1]
 *       "destination": [???]
 */
export function requestUpgrade(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;
    const { target, alg, destination, upgradetype, url, checksum, reboot_device, factory_reset } = req.body;

    directives(user_id, req.app_used, req.log).requestUpgrade({
        device_id, 
        target, 
        alg, 
        destination, 
        upgradetype, 
        url, 
        checksum, 
        reboot_device, 
        factory_reset 
    })
    .then(() => res.send())
    .catch(err => next(err));
}

export function runZitTest(req, res) {
    const { deviceid: device_id, user_id } = req.params;

    directives(user_id, req.app_used, req.log).runZitTest({ device_id })
        .then(() => res.send())
        .catch(err => next(err));

}

export function factoryReset(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;

    directives(user_id, req.app_used, req.log).factoryReset({ device_id })
        .then(() => res.send())
        .catch(err => next(err));
}

export function updateProfileParameters(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;
    const data = req.body;

    directives(user_id, req.app_used, req.log).updateProfileParameters({ device_id, data })
        .then(() => res.send())
        .catch(err => next(err));
}

export function getProfileParameters(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;
    const profileParams = req.body;

    directives(user_id, req.app_used, req.log).getProfileParameters({ device_id, profileParams })
        .then(() => res.send())
        .catch(err => next(err));
}

export function getVersion(req, res, next) {
    const { deviceid: device_id, user_id } = req.params;

    directives(user_id, req.app_used, req.log).getVersion({ device_id })
        .then(() => res.send())
        .catch(err => next(err));
}

export function retrievePermissions(req, res) {
    const { location_id } = req.params;
    const { user_id } = req.authenticated_user;

    userRoles(user_id)
        .then(roles => {
            const isAdmin = roles.indexOf('system.admin') >= 0;
            const groupIds = roles
                .map(role => (role.match(/AccountGroup\.(.+)\.admin/) || [])[1])
                .filter(groupId => groupId);
            let perms = [];

            if (isAdmin) {
                perms.push( 
                    createMqttDeviceTopicPermissions('+', 'telemetry', 'sub'),
                    createMqttDeviceTopicPermissions('+', 'will', 'sub'),
                    createMqttDeviceTopicPermissions('+', 'test-result/vrzit', 'sub'),
                    createMqttDeviceTopicPermissions('+', 'test-result/mvrzit', 'sub'),
                    createMqttDeviceTopicPermissions('+', 'directives-response', 'sub')
                );
            } 

            if (groupIds.length) {
                perms = groupIds
                    .map(groupId => [
                        createMqttGroupTopicPermissions(groupId, 'telemetry', 'sub'),
                        createMqttGroupTopicPermissions(groupId, 'will', 'sub'),
                        createMqttGroupTopicPermissions(groupId, 'test-result/vrzit', 'sub'),
                        createMqttGroupTopicPermissions(groupId, 'test-result/mvrzit', 'sub'),
                        createMqttGroupTopicPermissions(groupId, 'directives-response', 'sub')
                    ])
                    .reduce((acc, groupPerms) => acc.concat(groupPerms), [])
                    .concat(perms);
            }

            if (location_id) {
                return Promise.all([
                    icd.retrieveByLocationId({ location_id }),
                    pairingPermission.retrieveLatestByUserId({ user_id })
                ])
                .then(([icdResult, pairingPermissionResult]) => {
                    return (pairingPermissionResult.Items || [])
                        .filter(({ timestamp, ttl_mins }) => moment().utc().isBefore(moment(timestamp).add(ttl_mins, 'minutes')))
                        .concat(icdResult.Items || [])
                        .map(({ device_id }) => [ 
                            createMqttDeviceTopicPermissions(device_id, 'telemetry', 'sub'),
                            createMqttDeviceTopicPermissions(device_id, 'will', 'sub'),
                            createMqttDeviceTopicPermissions(device_id, 'test-result/vrzit', 'sub'),
                            createMqttDeviceTopicPermissions(device_id, 'test-result/mvrzit', 'sub'),
                            createMqttDeviceTopicPermissions(device_id, 'directives-response', 'sub')
                        ])
                        .reduce((acc, devicePerms) => acc.concat(devicePerms), [])
                        .concat(perms)
                });
            } else {
                return perms;
            }
        })
        .then(mqttTopicPermissions => {
            res.status(200).json(mqttTopicPermissions); 
        })
        .catch(err => next(err));
}

function createMqttDeviceTopicPermissions(deviceId, topic, activity) {
    return {
        topic: 'home/device/' + deviceId + '/v1/' + topic,
        activity: activity || 'ALL'
    };
}

function createMqttGroupTopicPermissions(groupId, topic, activity) {
    return {
        topic: 'home/group/' + groupId + '/device/+/v1/' + topic,
        activity: activity || 'ALL'
    };
}
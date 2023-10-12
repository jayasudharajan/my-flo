import DirectiveLogTable from '../app/models/DirectiveLogTable';
import { ensureICD, icdTable } from './icdUtils';
import { send } from './kafkaUtils';
import uuid from 'node-uuid';
import moment from 'moment';
import { encrypt } from './encryptionUtils';
import { rejectForcedSleep, setForcedSleepMode } from './forcedSleep';
import { scheduleTask, createSchedulerMessage, cancelPendingTasksByIcdId } from './taskScheduler';

var config = require('../config/config');

var directiveLog = new DirectiveLogTable();
const topic = config.directivesKafkaTopic;

export default function (user_id, app_used, log) {
    return {    
        toggleValve({ icd_id, device_id, valveaction }) {

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    let message = createDirectiveMessage(icd_id, {
                        directive: valveaction + '-valve',
                        device_id,
                        data: {}
                    });

                    return icdTable.patch({ id: icd_id }, { target_valve_state: valveaction.toLowerCase() == 'open' ? 'open' : 'closed' })
                        .then(() => sendDirective(user_id, message));
                });
        },
        powerReset({ icd_id, device_id }) {
    
            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    let message = createDirectiveMessage(icd_id, {
                        directive: 'power-reset',
                        device_id,
                        data: {}
                    });

                    return sendDirective(user_id, message);
                });
        },
        setSystemMode({ icd_id, device_id, systemmodeid }) {
            let icdId = null;
            let deviceid = null;

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    icdId = icd_id;
                    deviceid = device_id;

                    return rejectForcedSleep(icdId);
                })
                .then(() => {
                    let message = createDirectiveMessage(icdId, {
                        directive: 'set-system-mode',
                        device_id: deviceid,
                        data: {
                            mode: systemmodeid
                        }
                    });
                    const systemModeName = translateSystemMode(systemmodeid);

                    return icdTable.patch({ id: icdId }, { target_system_mode: systemModeName } )
                        .then(() => Promise.all([
                            sendDirective(user_id, message),
                            cancelPendingTasksByIcdId(icdId, 'sleep')
                        ]));
                });
        },
        enableForcedSleep({ icd_id, device_id }) {

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    const msg = createDirectiveMessage(icd_id, {
                        directive: 'set-system-mode',
                        device_id,
                        data: {
                            mode: 5 
                        }
                    });

                    return icdTable.patch({ id: icd_id }, { target_system_mode: 'sleep' })
                        .then(() => Promise.all([
                            setForcedSleepMode(icd_id, user_id, true),
                            sendDirective(user_id, msg),
                            cancelPendingTasksByIcdId(icd_id, 'sleep')
                        ]));
                });
        },    
        disableForcedSleep({ icd_id, device_id }) {

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => 
                    Promise.all([
                        setForcedSleepMode(icd_id, user_id, false),
                        cancelPendingTasksByIcdId(icd_id, 'sleep')
                    ])
                );
        },  
        sleep({ icd_id: icdId, device_id, systemmodeid, sleep_minutes }) {
            let sleepTime = moment().add(sleep_minutes, 'minutes').utc();
            let icd_id = null;
            let deviceid = null;

            if (!sleep_minutes || sleep_minutes <= 0) {
                return new Promise((resolve, reject) => reject({ status: 400, message: "Invalid sleep time." }));
            }

            return ensureICD({ icd_id: icdId, device_id, log })
                .then(({ icd_id: id, device_id }) => {
                    icd_id = id;
                    deviceid = device_id;

                    return rejectForcedSleep(icd_id);
                })
                .then(() => {
                    return cancelPendingTasksByIcdId(icd_id, 'sleep');
                })
                .then(() => {

                    let encryptMsg = msg => (config.encryption.kafka.encryptionEnabled ? encrypt('kafka', msg) : new Promise(resolve => resolve(msg)));
                    let msg = createDirectiveMessage(icd_id, {
                        directive: 'set-system-mode',
                        device_id: deviceid,
                        time: sleepTime.toISOString(),
                        data: {
                            mode: systemmodeid || 2 // default to Home mode
                        }
                    });


                    return Promise.all([
                        encryptMsg(JSON.stringify(msg)), 
                        new Promise(resolve => resolve(msg))
                    ]);
                })
                .then(([delayedDirectiveMsg, unencrypted]) => {
                    let schedulerMsg = createSchedulerMessage(topic, delayedDirectiveMsg, sleepTime, `sleep:${icd_id}:${uuid.v4()}`);
                    let directiveMessage = createDirectiveMessage(icd_id, {
                        directive: 'set-system-mode',
                        device_id: deviceid,
                        data: {
                            mode: 5 // Manual mode
                        }
                    }); 
                    const systemModeName = translateSystemMode(systemmodeid);
 
                    return icdTable.patch({ id: icd_id }, { 
                        target_system_mode: 'sleep', 
                        revert_mode: systemModeName,
                        revert_minutes: sleep_minutes,
                        revert_scheduled_at: moment().add(sleep_minutes, 'minutes').toISOString()
                    })
                    .then(() => Promise.all([
                        sendDirective(user_id, directiveMessage),
                        scheduleTask(schedulerMsg, { icd_id, directive: unencrypted, task_type: 'sleep' })
                    ]));
                });
        },
        requestUpgrade({ icd_id, device_id, target, alg, destination, upgradetype, url, checksum, rebootDevice, factoryReset }) {
            let data = null;

            switch (upgradetype) {
                case 'upgrade-ultima':
                    data = {
                        target: target || 'agent-1',
                        url: url,
                        checksum: checksum,
                        alg: alg || 'sha1',
                        destination: destination ||  '',
                        reboot_device: rebootDevice || false,
                        factory_reset: factoryReset || false
                    };
                    break;
                case 'upgrade-kernel':
                    data = {
                        target: target || 'agent-1',
                        url: url,
                        checksum: checksum,
                        alg: alg || 'sha1',
                        reboot_device: true,
                        factory_reset: factoryReset || false
                    };
                    break;
                case 'upgrade-agent-1':
                case 'upgrade-agent-2':
                    data = {
                        target: upgradetype === 'upgrade-agent-1' ? 'agent-2' : 'agent-1',
                        url: url,
                        checksum: checksum,
                        alg: alg || 'sha1',
                        reboot_device: rebootDevice || false
                    };
                    break;
                case 'upgrade-certificates':
                    data = {
                        target: target || 'agent-1',
                        url: url,
                        checksum: checksum,
                        alg: alg || 'sha1',
                        destination: destination || '',
                    };
                    break;
                default:
                    return new Promise((resolve, reject) => reject('Invalid upgrade.'));
            }

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    let message = createDirectiveMessage(icd_id, {
                        directive: upgradetype,
                        device_id,
                        data: data
                    });

                    return sendDirective(user_id, message);
                });
        },    
        runZitTest({ icd_id, device_id }) {

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    let message = createDirectiveMessage(icd_id, {
                        directive: 'vrzit',
                        device_id,
                        data: {
                            round_id: uuid.v4(),
                            pressure_percentage: 3.0,
                            reference_time: 120,
                            reference_point_count: 3,
                            slope_decrease: 0.6,
                            stage_1_time_factor: 0.5,
                            stage_2_time_factor: 1,
                            stage_3_time_factor: 2,
                            stage_4_time_factor: 4
                        }
                    });

                    return sendDirective(user_id, message);
                });

        },
        factoryReset({ icd_id, device_id }) {

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    let message = createDirectiveMessage(icd_id, {
                        directive: 'factory-reset',
                        device_id,
                        data: {
                            "reset_kernel": !!req.body['reset_kernel'],
                            "reset_ultima": !!req.body['reset_ultima']
                        }
                    });

                    return sendDirective(user_id, message);
                });
        },
        updateProfileParameters({ icd_id, device_id, data }) {

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    let message = createDirectiveMessage(icd_id, {
                        directive: 'update-profile',
                        device_id,
                        data: data
                    });

                    return sendDirective(user_id, message);
                });
        },    
        getProfileParameters({ icd_id, device_id, profileParams }) {

            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    let message = createDirectiveMessage(icd_id, {
                        directive: 'get-profile',
                        device_id
                    });

                    return sendDirective(user_id, message);
                });
        },
        getVersion({ icd_id, device_id }) {
            return ensureICD({ icd_id, device_id, log })
                .then(({ icd_id, device_id }) => {
                    const message = createDirectiveMessage(icd_id, {
                        directive: 'get-version',
                        device_id
                    });

                    return sendDirective(user_id, message);
                });
        }
    };

    function createDirectiveMessage(icd_id, directiveData) {
        const state = 1;
        const directive = {
            time: new Date().toISOString(),
            id:  uuid.v4(),
            ack_topic: '',
            data: {},
            ...(directiveData || {})
        };

        return {
            icd_id,
            state,
            directive
        };
    }

    function sendDirective(user_id, message) {
        let { directive, icd_id } = message;
        let kafkaPromise = send(topic, JSON.stringify(message), false, directive.device_id);
        let logPromise = directiveLog.create({
            icd_id,
            user_id,
            status: 'init',
            directive_type: directive.directive,
            directive_id: directive.id,
            directive: JSON.stringify(directive),
            app_used: app_used,
            created_at: directive.time
        });

        return Promise.all([kafkaPromise, logPromise]);
    }

    function translateSystemMode(systemMode) {
        return systemMode == 2 ?
            'home' :
            systemMode == 3 ?
              'away' :
              systemMode == 5 ?
                'sleep' :
                'home';
    }
}
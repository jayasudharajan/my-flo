import ICDForcedSystemModeTable from '../app/models/ICDForcedSystemModeTable';

const icdForcedSystemMode = new ICDForcedSystemModeTable();

export function isInForcedSleep(icd_id) {
    return icdForcedSystemMode.retrieveLatestByIcdId({ icd_id })
        .then(({ Items }) => {
            // Currently the only values used for system_mode are null and 5
            return Items.length && Items[0].system_mode;
        });
}

export function rejectForcedSleep(icd_id) {
    let deferred = Promise.defer();

    isInForcedSleep(icd_id)
        .then(forcedSleep => {
            if (!forcedSleep) {
                deferred.resolve(false);
            } else {
                deferred.reject({ status: 409, message: 'System mode cannot be changed. Please contact Flo Support for more information.' });
            }
        });

    return deferred.promise;
}

export function setForcedSleepMode(icd_id, user_id, isEnabled) {
    const params = {
        icd_id: icd_id,
        created_at: new Date().toISOString(),
        system_mode: isEnabled ? 5 : null,
        performed_by_user_id: user_id
    };

    return icdForcedSystemMode.create(params);
}
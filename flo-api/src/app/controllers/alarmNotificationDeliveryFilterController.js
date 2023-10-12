import _ from 'lodash';
import AlarmNotificationDeliveryFilterTable from '../models/AlarmNotificationDeliveryFilterTable';
import { stripCollection } from '../../util/utils';

let AlarmNotificationDeliveryFilter = new AlarmNotificationDeliveryFilterTable();

function createKeys(hash_key, range_keys) {
  return {
    icd_id: hash_key,
    alarm_id_system_mode: createCompoundRangeKey(range_keys)
  };
}

function createCompoundRangeKey(keys) {
  return keys.alarm_id + "_" + keys.system_mode;
}

function addCompoundRangeKey(data) {
  let { alarm_id, system_mode } = data;
  data.alarm_id_system_mode = createCompoundRangeKey({ alarm_id, system_mode });
  return data;
}

/**
 * Retrieve one AlarmNotificationDeliveryFilter.
 */
export function retrieve(req, res, next) {

  let { icd_id, alarm_id, system_mode } = req.params;
  let keys = createKeys(icd_id, { alarm_id, system_mode });

  AlarmNotificationDeliveryFilter.retrieve(keys)
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        delete result.Item.alarm_id_system_mode
        res.json(result.Item);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create one AlarmNotificationDeliveryFilter.
 */
export function create(req, res, next) {

  AlarmNotificationDeliveryFilter.create(addCompoundRangeKey(req.body))
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Update one item.  (replace)
 */
export function update(req, res, next) {

  const { icd_id, alarm_id, system_mode } = req.params;
  // Add url keys into request body.
  req.body.icd_id = icd_id;
  req.body.alarm_id = alarm_id;
  req.body.system_mode = system_mode;

  AlarmNotificationDeliveryFilter.update(addCompoundRangeKey(req.body))
    .then(result => {
      delete result.alarm_id_system_mode;
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one AlarmNotificationDeliveryFilter.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { icd_id, alarm_id, system_mode } = req.params;
  let keys = createKeys(icd_id, { alarm_id, system_mode });

  AlarmNotificationDeliveryFilter.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one AlarmNotificationDeliveryFilter.
 */
export function remove(req, res, next) {

  const { icd_id, alarm_id, system_mode } = req.params;
  let keys = createKeys(icd_id, { alarm_id, system_mode });

  AlarmNotificationDeliveryFilter.remove(keys)
    .then(result => {
      if(!result) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(result);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Archive ('delete') one AlarmNotificationDeliveryFilter.
 */
export function archive(req, res, next) {

  const { icd_id, alarm_id_system_mode } = req.params;
  let keys = { icd_id, alarm_id_system_mode };

  AlarmNotificationDeliveryFilter.archive(keys)
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        // Returns: { Attributes: { is_deleted: true } }
        res.json(result);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Simple Table scan to retrieve multiple records.
 */
export function scan(req, res, next) {

  AlarmNotificationDeliveryFilter.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get AlarmNotificationDeliveryFilter by icd_id.
 */
export function retrieveByICDId(req, res, next) {

  const { icd_id } = req.params;
  AlarmNotificationDeliveryFilter.retrieveByICDId({ icd_id })
    .then(result => {
      if(!_.isEmpty(result.Items)) {
        res.json(stripCollection(result.Items, 'alarm_id_system_mode'));
      } else {
        next({ status: 404, message: "No records found."  });
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get AlarmNotificationDeliveryFilter by icd_id and alarm_id.
 */
export function retrieveByICDIdAlarmId(req, res, next) {

  const { icd_id, alarm_id } = req.params;

  AlarmNotificationDeliveryFilter.retrieveByICDIdAlarmId({ icd_id, alarm_id })
    .then(result => {
      if(!_.isEmpty(result.Items)) {
        res.json(stripCollection(result.Items, 'alarm_id_system_mode'));
      } else {
        next({ status: 404, message: "No records found."  });
      }
    })
    .catch(err => {
      next(err);
    });

}

export function retrieveHighestSeverityByICDId(req, res, next) {

  const { icd_id } = req.params;

  AlarmNotificationDeliveryFilter.retrieveHighestSeverityByICDId({ icd_id })
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });

}
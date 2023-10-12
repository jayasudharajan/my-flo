import _ from 'lodash';
import UserAlarmNotificationDeliveryRuleTable from '../models/UserAlarmNotificationDeliveryRuleTable';
import { stripCollection } from '../../util/utils';

let userAlarmNotificationDeliveryRule = new UserAlarmNotificationDeliveryRuleTable();

function createKeys(hash_key, range_keys) {
  return { 
    user_id: hash_key, 
    location_id_alarm_id_system_mode: createCompoundRangeKey(range_keys)
  };
}

function createCompoundRangeKey(keys) {
  return keys.location_id + "_" + keys.alarm_id + "_" + keys.system_mode;
}

function addCompoundRangeKey(data) {
  let { location_id, alarm_id, system_mode } = data;
  data.location_id_alarm_id_system_mode = createCompoundRangeKey({ location_id, alarm_id, system_mode });
  return data;
}

/**
 * Retrieve one userAlarmNotificationDeliveryRule.
 */
export function retrieve(req, res, next) {

  let { user_id, location_id, alarm_id, system_mode } = req.params;
  let keys = createKeys(user_id, { location_id, alarm_id, system_mode });

  userAlarmNotificationDeliveryRule.retrieve(keys)
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        delete result.Item.location_id_alarm_id_system_mode
        res.json(result.Item);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create one userAlarmNotificationDeliveryRule.
 */
export function create(req, res, next) {

  userAlarmNotificationDeliveryRule.create(addCompoundRangeKey(req.body))
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

  const { user_id, location_id, alarm_id, system_mode } = req.params;

  // Add url keys into request body.
  req.body.user_id = user_id;
  req.body.location_id = location_id;
  req.body.alarm_id = alarm_id;
  req.body.system_mode = system_mode;

  userAlarmNotificationDeliveryRule.update(addCompoundRangeKey(req.body))
    .then(result => {
      delete result.Item.location_id_alarm_id_system_mode;
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one userAlarmNotificationDeliveryRule.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { user_id, location_id, alarm_id, system_mode } = req.params;

  let keys = createKeys(user_id, { location_id, alarm_id, system_mode });
  userAlarmNotificationDeliveryRule.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one userAlarmNotificationDeliveryRule.
 */
export function remove(req, res, next) {

  const { user_id, location_id, alarm_id, system_mode } = req.params;

  let keys = createKeys(user_id, { location_id, alarm_id, system_mode });
  userAlarmNotificationDeliveryRule.remove(keys)
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
 * Simple Table scan to retrieve multiple records.
 */
export function scan(req, res, next) {

  userAlarmNotificationDeliveryRule.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set userAlarmNotificationDeliveryRule with same hashkey.
 */
export function retrieveByUserId(req, res, next) {

  const { user_id } = req.params;
  userAlarmNotificationDeliveryRule.retrieveByUserId({ user_id })
    .then(result => {
      if(!_.isEmpty(result.Items)) {
          res.json(stripCollection(result.Items, 'location_id_alarm_id_system_mode'));
        } else {
          next({ status: 404, message: "No records found."  });
        }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get by user_id & location_id.
 */
export function retrieveByUserIdLocationId(req, res, next) {

  const { user_id, location_id } = req.params;
  userAlarmNotificationDeliveryRule.retrieveByUserIdLocationId({ user_id, location_id })
    .then(result => {
      if(!_.isEmpty(result.Items)) {
          res.json(stripCollection(result.Items, 'location_id_alarm_id_system_mode'));
        } else {
          next({ status: 404, message: "No records found."  });
        }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get by user_id & location_id.
 */
export function retrieveByLocationIdAlarmId(req, res, next) {

  let { location_id, alarm_id } = req.params;
  alarm_id = parseInt(alarm_id);

  userAlarmNotificationDeliveryRule.retrieveByLocationIdAlarmId(
      { location_id, alarm_id })
    .then(result => {
      if(!_.isEmpty(result.Items)) {
        res.json(stripCollection(result.Items, 'location_id_alarm_id_system_mode'));
      } else {
        next({ status: 404, message: "No records found."  });
      }

    })
    .catch(err => {
      next(err);
    });
}

/**
 * Get by location_id, alarm_id, system_mode.
 */
export function retrieveByLocationIdAlarmIdSystemMode(req, res, next) {

  const { location_id, alarm_id, system_mode } = req.params;

  userAlarmNotificationDeliveryRule.retrieveByLocationIdAlarmIdSystemMode({ location_id, alarm_id, system_mode })
    .then(result => {
      if(!_.isEmpty(result.Items)) {
        res.json(stripCollection(result.Items, 'location_id_alarm_id_system_mode'));
      } else {
        next({ status: 404, message: "No records found."  });
      }
    })
    .catch(err => {
      next(err);
    });
}

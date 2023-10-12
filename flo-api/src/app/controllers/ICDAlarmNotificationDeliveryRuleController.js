import _ from 'lodash';
import ICDAlarmNotificationDeliveryRuleTable from '../models/ICDAlarmNotificationDeliveryRuleTable';
let ICDAlarmNotificationDeliveryRule = new ICDAlarmNotificationDeliveryRuleTable();

/**
 * Retrieve one ICDAlarmNotificationDeliveryRule.
 */
export function retrieve(req, res, next) {

  const { alarm_id, system_mode } = req.params;
  let keys = { alarm_id: parseInt(alarm_id, 10), system_mode: parseInt(system_mode, 10) };

  ICDAlarmNotificationDeliveryRule.retrieve(keys, req.log)
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(result.Item);
      }
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Create one ICDAlarmNotificationDeliveryRule.
 */
export function create(req, res, next) {

  ICDAlarmNotificationDeliveryRule.create(req.body)
    .then(result => {
      res.json(result); // For a successful create - this will return an empty collection.
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Replace one ICDAlarmNotificationDeliveryRule.
 */
export function update(req, res, next) {

  let { alarm_id, system_mode } = req.params;
  alarm_id = parseInt(alarm_id, 10);
  system_mode = parseInt(alarm_id, 10);
  // Add url keys into request body.
  req.body.alarm_id = alarm_id;
  req.body.system_mode = system_mode;

  ICDAlarmNotificationDeliveryRule.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one ICDAlarmNotificationDeliveryRule.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { alarm_id, system_mode } = req.params;
  let keys = { alarm_id: parseInt(alarm_id, 10), system_mode: parseInt(system_mode, 10) };

  ICDAlarmNotificationDeliveryRule.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one ICDAlarmNotificationDeliveryRule.
 */
export function remove(req, res, next) {

  const { alarm_id, system_mode } = req.params;
  let keys = { alarm_id: parseInt(alarm_id, 10), system_mode: parseInt(system_mode, 10) };

  ICDAlarmNotificationDeliveryRule.remove(keys)
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
 * Archive ('delete') one ICDAlarmNotificationDeliveryRule.
 */
export function archive(req, res, next) {

  const { alarm_id, system_mode } = req.params;
  let keys = { alarm_id: parseInt(alarm_id, 10), system_mode: parseInt(system_mode, 10) };

  ICDAlarmNotificationDeliveryRule.archive(keys)
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

  ICDAlarmNotificationDeliveryRule.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Query set ICDAlarmNotificationDeliveryRule with same hashkey.
 */
export function retrieveByAlarmId(req, res, next) {

  let { alarm_id } = req.params;

  ICDAlarmNotificationDeliveryRule.retrieveByAlarmId({ alarm_id: parseInt(alarm_id, 10) })
    .then(result => {
      res.json(result.Items);
    })
    .catch(err => {
      next(err);
    });
}

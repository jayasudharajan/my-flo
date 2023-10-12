import _ from 'lodash';
import PushNotificationDeliveryLogTable from '../models/PushNotificationDeliveryLogTable';
let pushNotificationDeliveryLog = new PushNotificationDeliveryLogTable();

/**
 * Retrieve one pushNotificationDeliveryLog.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  pushNotificationDeliveryLog.retrieve(keys)
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
 * Create one pushNotificationDeliveryLog.
 */
export function create(req, res, next) {

  pushNotificationDeliveryLog.create(req.body)
    .then(result => {
      res.json(result); // For a successful create - this will return an empty collection.
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Update one item.  (replace)
 */
export function update(req, res, next) {

  const { id } = req.params;

  // Add url keys into request body.
  req.body.id = id;

  pushNotificationDeliveryLog.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one pushNotificationDeliveryLog.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  pushNotificationDeliveryLog.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one pushNotificationDeliveryLog.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  pushNotificationDeliveryLog.remove(keys)
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
 * Archive ('delete') one pushNotificationDeliveryLog.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };
  
  pushNotificationDeliveryLog.archive(keys)
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

  pushNotificationDeliveryLog.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

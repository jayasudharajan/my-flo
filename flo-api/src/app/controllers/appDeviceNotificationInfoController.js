import _ from 'lodash';
import AppDeviceNotificationInfoTable from '../models/AppDeviceNotificationInfoTable';
let appDeviceNotificationInfo = new AppDeviceNotificationInfoTable();

/**
 * Retrieve one appDeviceNotificationInfo.
 */
export function retrieve(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  appDeviceNotificationInfo.retrieve(keys)
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
 * Create one appDeviceNotificationInfo.
 */
export function create(req, res, next) {

  appDeviceNotificationInfo.create(req.body)
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

  appDeviceNotificationInfo.update(req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Patch one appDeviceNotificationInfo.  Use this to update individual fields.
 */
export function patch(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  appDeviceNotificationInfo.patch(keys, req.body)
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

/**
 * Delete one appDeviceNotificationInfo.
 */
export function remove(req, res, next) {

  const { id } = req.params;
  let keys = { id };

  appDeviceNotificationInfo.remove(keys)
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
 * Archive ('delete') one appDeviceNotificationInfo.
 */
export function archive(req, res, next) {

  const { id } = req.params;
  let keys = { id };
  
  appDeviceNotificationInfo.archive(keys)
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

  appDeviceNotificationInfo.scanAll()
    .then(result => {
      res.json(result);
    })
    .catch(err => {
      next(err);
    });
}

export function retrieveByUserIdICDId(req, res, next) {

  const { user_id, icd_id } = req.params;

  appDeviceNotificationInfo.retrieveByUserIdICDId({ user_id, icd_id })
    .then(result => {
      if(_.isEmpty(result)) {
        next({ status: 404, message: "Item not found."  });
      } else {
        res.json(result.Items);
      }
    })
    .catch(err => {
      next(err);
    });

}
